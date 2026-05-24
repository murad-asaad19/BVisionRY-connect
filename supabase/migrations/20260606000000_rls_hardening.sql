-- RLS hardening pass: tighten WITH CHECK, revoke direct UPDATE on sensitive columns,
-- close race window in accept_intro, restrict definer-only helpers, add device-token unregister.

-- ============================================================
-- #1  profiles: WITH CHECK on UPDATE + column-level UPDATE revoke
-- ============================================================
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

revoke update (
  verified_github_id,
  verified_github_username,
  verified_at,
  suspended_at,
  onboarded,
  private_mode,
  public_investor_page
) on public.profiles from authenticated;

-- ============================================================
-- #2  messages: restrict direct INSERT to kind='text'.
-- TODO: add send_image_message / send_voice_message / send_meeting_message RPCs
-- (SECURITY DEFINER) and remove direct image/voice/meeting client INSERT paths.
-- ============================================================
drop policy if exists messages_insert_participant on public.messages;
create policy messages_insert_participant on public.messages
  for insert
  with check (
    sender_id = auth.uid()
    and kind = 'text'::public.message_kind
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
    )
  );

-- ============================================================
-- #3  daily_matches: add WITH CHECK to update policy
-- ============================================================
drop policy if exists daily_matches_update_own on public.daily_matches;
create policy daily_matches_update_own on public.daily_matches
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- #6  should_notify: drop authenticated grant (only used by definer triggers)
-- ============================================================
revoke execute on function public.should_notify(
  uuid,
  public.notification_kind,
  public.notification_channel
) from authenticated;

-- ============================================================
-- #7  Revoke execute-from-public on internal scoring helpers
-- ============================================================
revoke execute on function public.match_score(uuid, uuid) from public;
revoke execute on function public.match_reason_for(uuid, uuid) from public;
revoke execute on function public.goals_complementary(public.goal_type, public.goal_type) from public;

-- ============================================================
-- #9  accept_intro: re-check blocks before creating conversation
-- ============================================================
create or replace function public.accept_intro(p_intro_id uuid)
returns public.intros
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_intro public.intros;
  v_a uuid;
  v_b uuid;
  v_conv_id uuid;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  select * into v_intro from public.intros where id = p_intro_id for update;
  if not found then raise exception 'intro not found' using errcode = 'P0002'; end if;
  if v_intro.recipient_id is distinct from v_caller then
    raise exception 'only the recipient can accept' using errcode = '42501';
  end if;
  if v_intro.state <> 'delivered'::public.intro_state then
    raise exception 'intro not in delivered state' using errcode = '22023';
  end if;
  if v_intro.expires_at < now() then
    raise exception 'intro has expired' using errcode = '22023';
  end if;
  if v_intro.sender_id is null then
    raise exception 'sender no longer exists' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.blocks
    where (blocker_id = v_intro.sender_id    and blocked_id = v_intro.recipient_id)
       or (blocker_id = v_intro.recipient_id and blocked_id = v_intro.sender_id)
  ) then
    raise exception 'blocked' using errcode = '42501';
  end if;

  if v_intro.sender_id < v_intro.recipient_id then
    v_a := v_intro.sender_id; v_b := v_intro.recipient_id;
  else
    v_a := v_intro.recipient_id; v_b := v_intro.sender_id;
  end if;

  select id into v_conv_id
    from public.conversations
   where participant_a_id = v_a and participant_b_id = v_b;

  if v_conv_id is null then
    insert into public.conversations (participant_a_id, participant_b_id)
    values (v_a, v_b)
    returning id into v_conv_id;
  end if;

  update public.intros
  set state = 'connected'::public.intro_state,
      conversation_id = v_conv_id
  where id = p_intro_id
  returning * into v_intro;

  return v_intro;
end;
$$;

-- ============================================================
-- #10  conversation_reads_update_own: add WITH CHECK
-- ============================================================
drop policy if exists conversation_reads_update_own on public.conversation_reads;
create policy conversation_reads_update_own on public.conversation_reads
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================
-- #11  unregister_device_token RPC
-- ============================================================
create or replace function public.unregister_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if p_token is null or length(p_token) = 0 then
    raise exception 'invalid token' using errcode='22023';
  end if;
  delete from public.device_tokens
  where user_id = v_user and token = p_token;
end;
$$;
grant execute on function public.unregister_device_token(text) to authenticated;

-- ============================================================
-- Summary of changes in this migration
-- ============================================================
-- #1  profiles.UPDATE has WITH CHECK; sensitive columns no longer writable via PostgREST
-- #2  messages direct INSERT restricted to kind='text' (image/voice/meeting need RPCs — TODO)
-- #3  daily_matches.UPDATE has WITH CHECK
-- #6  should_notify execute revoked from authenticated
-- #7  match_score / match_reason_for / goals_complementary execute revoked from public
-- #9  accept_intro re-checks blocks under row lock before creating conversation
-- #10 conversation_reads.UPDATE has WITH CHECK
-- #11 unregister_device_token(text) RPC added
