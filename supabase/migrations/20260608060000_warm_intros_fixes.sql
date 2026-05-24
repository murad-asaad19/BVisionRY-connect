-- Warm-intro hardening fixes: five post-review issues uncovered after the
-- 2nd-degree warm-intro feature landed in 20260608010000_second_degree_intros.sql.
--
-- Fixes
-- -----
--
-- #3  (CRITICAL — data corruption)
--     accept_intro did not branch on intros.kind. Accepting a warm_request via
--     the legacy direct-intro path would spawn a conversation between the
--     asker and the mutual and silently bury the warm_target_id. We extend
--     accept_intro to reject any non-'direct' intro kind.
--
-- #14 (cooldown poisoning)
--     decline_intro stamped declined_at unconditionally, triggering the
--     30-day cooldown in send_intro/send_warm_request between asker and
--     mutual. Asker and mutual are already connected — the cooldown there is
--     meaningless — but the bigger issue is the row poisons future retries
--     for the same target via a different mutual (gated by #8 below).
--     decline_intro on a warm_request now transitions to 'declined' WITHOUT
--     stamping declined_at.
--
-- #7  (anti-shotgun)
--     send_warm_request only deduped (sender, recipient) and (mutual, target).
--     An asker could shotgun the same target through every mutual they
--     shared. We now reject if the same asker has any pending or delivered
--     warm_request for the same warm_target_id, regardless of which mutual.
--
-- #8  (suggest filter bug)
--     suggest_warm_intros NOT-EXISTS only checked recipient_id = candidate
--     target, but warm_request rows have recipient_id = mutual with the
--     target in warm_target_id. An asker who already had a pending
--     warm_request about a target still saw that target re-suggested. The
--     filter now also excludes pending/delivered warm_requests by
--     warm_target_id.
--
-- #15 (forwarder surfacing)
--     forward_warm_intro synthesises a warm_forward with sender_id = asker.
--     The target's push payload showed only the asker; the mutual's note
--     appeared to come from the asker. We extend the push payload for
--     warm_forward kind to carry via_user_id + via_user_name so the client
--     can render "Forwarded by Alice" prominently in the OS push AND inside
--     the intro card. The trigger now also overrides the legacy title/body
--     for warm_forward intros so the OS push surface shows the chain.

-- =============================================================================
-- #3 + #14: accept_intro + decline_intro — add kind branching.
-- =============================================================================

-- accept_intro: refuse non-'direct' kinds outright. Body otherwise unchanged
-- from 20260606000000_rls_hardening.sql (canonical definition).
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

  -- Kind gate: a warm_request must be forwarded (forward_warm_intro), not
  -- accepted. A warm_forward is target-facing and is accepted via this RPC
  -- as a normal intro, so we allow 'direct' AND 'warm_forward'. Only
  -- 'warm_request' must be refused — its acceptance path is forward_warm_intro.
  if v_intro.kind = 'warm_request'::public.intro_kind then
    raise exception 'wrong intro kind' using errcode = '22023';
  end if;

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

-- decline_intro: for warm_request kind, transition state to 'declined' but
-- DO NOT stamp declined_at — the 30-day cooldown between asker and mutual is
-- meaningless (they're already connected) and stamping it blocks retries.
-- The asker can immediately retry the warm_request through a different mutual
-- (gated by the suggest_warm_intros NOT-EXISTS fix below; the per-target
-- single-outstanding check in send_warm_request still applies).
create or replace function public.decline_intro(p_intro_id uuid)
returns public.intros
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_intro public.intros;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  select * into v_intro from public.intros where id = p_intro_id for update;
  if not found then raise exception 'intro not found' using errcode = 'P0002'; end if;
  if v_intro.recipient_id is distinct from v_caller then
    raise exception 'only the recipient can decline' using errcode = '42501';
  end if;
  if v_intro.state <> 'delivered'::public.intro_state then
    raise exception 'intro not in delivered state' using errcode = '22023';
  end if;

  if v_intro.kind = 'warm_request'::public.intro_kind then
    -- No declined_at stamp: don't poison send_intro/send_warm_request cooldown.
    update public.intros
       set state = 'declined'::public.intro_state
     where id = p_intro_id
     returning * into v_intro;
  else
    update public.intros
       set state       = 'declined'::public.intro_state,
           declined_at = now()
     where id = p_intro_id
     returning * into v_intro;
  end if;
  return v_intro;
end;
$$;

-- =============================================================================
-- #7: send_warm_request — anti-shotgun.
-- One outstanding warm_request per (asker, target) regardless of mutual.
-- =============================================================================
create or replace function public.send_warm_request(
  p_mutual_id uuid,
  p_target_id uuid,
  p_note text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_sender uuid := auth.uid();
  v_today_count int;
  v_intro_id uuid;
begin
  if v_sender is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  if p_mutual_id is null or p_target_id is null then
    raise exception 'mutual_id and target_id are required' using errcode = '22023';
  end if;
  if v_sender = p_mutual_id or v_sender = p_target_id or p_mutual_id = p_target_id then
    raise exception 'invalid triangle' using errcode = '22023';
  end if;

  -- #7 Anti-shotgun: only one outstanding warm_request per (asker, target).
  -- We do this BEFORE the note-length check so a quick retry through a
  -- different mutual short-circuits at the cheapest possible step.
  if exists (
    select 1 from public.intros
    where sender_id      = v_sender
      and warm_target_id = p_target_id
      and kind           = 'warm_request'::public.intro_kind
      and state in ('pending'::public.intro_state, 'delivered'::public.intro_state)
  ) then
    raise exception 'warm request already pending for target'
      using errcode = 'P0001', hint = 'warm_request_pending';
  end if;

  -- Note length: same window as direct intros (see send_intro).
  if char_length(btrim(p_note)) < 80 or char_length(btrim(p_note)) > 400 then
    raise exception 'note must be 80-400 characters' using errcode = '22023';
  end if;

  -- Mutual must be onboarded; target must be onboarded + not private + not suspended.
  if not exists (
    select 1 from public.profiles
    where id = p_mutual_id and onboarded = true
  ) then
    raise exception 'mutual not available' using errcode = 'P0002';
  end if;
  if not exists (
    select 1 from public.profiles
    where id = p_target_id
      and onboarded = true
      and private_mode = false
      and suspended_at is null
  ) then
    raise exception 'target not available' using errcode = 'P0002';
  end if;

  -- Block check across the whole triangle.
  if exists (
    select 1 from public.blocks
    where (blocker_id = v_sender    and blocked_id = p_mutual_id)
       or (blocker_id = p_mutual_id and blocked_id = v_sender)
       or (blocker_id = v_sender    and blocked_id = p_target_id)
       or (blocker_id = p_target_id and blocked_id = v_sender)
       or (blocker_id = p_mutual_id and blocked_id = p_target_id)
       or (blocker_id = p_target_id and blocked_id = p_mutual_id)
  ) then
    raise exception 'blocked' using errcode = '42501';
  end if;

  -- viewer↔mutual must be a connection.
  if not exists (
    select 1 from public.intros
    where state = 'connected'::public.intro_state
      and (
        (sender_id = v_sender    and recipient_id = p_mutual_id)
        or
        (sender_id = p_mutual_id and recipient_id = v_sender)
      )
  ) then
    raise exception 'no connection to mutual' using errcode = '42501';
  end if;

  -- mutual↔target must be a connection.
  if not exists (
    select 1 from public.intros
    where state = 'connected'::public.intro_state
      and (
        (sender_id = p_mutual_id and recipient_id = p_target_id)
        or
        (sender_id = p_target_id and recipient_id = p_mutual_id)
      )
  ) then
    raise exception 'mutual has no connection to target' using errcode = '42501';
  end if;

  -- viewer must NOT already have any intros row with the target (any state).
  if exists (
    select 1 from public.intros
    where (sender_id = v_sender    and recipient_id = p_target_id)
       or (sender_id = p_target_id and recipient_id = v_sender)
  ) then
    raise exception 'intro to target already exists' using errcode = '23505';
  end if;

  -- viewer must NOT already have a pending warm_request to the same mutual for the same target.
  -- (Covered by the broader #7 check above, but kept here for the precise
  -- error message in the single-mutual retry case.)
  if exists (
    select 1 from public.intros
    where sender_id      = v_sender
      and recipient_id   = p_mutual_id
      and kind           = 'warm_request'::public.intro_kind
      and warm_target_id = p_target_id
      and state          = 'delivered'::public.intro_state
  ) then
    raise exception 'warm request already pending' using errcode = '23505';
  end if;

  -- 20/day outbound cap — warm_requests count toward the same bucket as send_intro.
  select count(*) into v_today_count
    from public.intros
   where sender_id = v_sender
     and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date;
  if v_today_count >= 20 then
    raise exception 'daily cap reached'
      using errcode = 'P0001', hint = 'daily_cap';
  end if;

  insert into public.intros (
    sender_id, recipient_id, note, state, kind, warm_target_id
  ) values (
    v_sender, p_mutual_id, btrim(p_note),
    'delivered'::public.intro_state,
    'warm_request'::public.intro_kind,
    p_target_id
  )
  returning id into v_intro_id;

  return v_intro_id;
end;
$$;

revoke all on function public.send_warm_request(uuid, uuid, text) from public, anon;
grant execute on function public.send_warm_request(uuid, uuid, text) to authenticated;

-- =============================================================================
-- #8: suggest_warm_intros — fix NOT-EXISTS filter to also exclude targets
-- the asker has a pending warm_request about (recipient_id = mutual,
-- warm_target_id = candidate target).
-- =============================================================================
create or replace function public.suggest_warm_intros(p_limit int default 10)
returns table (
  target_id uuid,
  target_handle text,
  target_name text,
  target_photo_url text,
  target_primary_role public.role_kind,
  target_goal_type public.goal_type,
  mutual_count int,
  top_mutual_id uuid,
  top_mutual_name text,
  top_mutual_handle text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_limit int := coalesce(p_limit, 10);
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  return query
  with viewer_conn as (
    select
      case when sender_id = v_user then recipient_id else sender_id end as other_id,
      updated_at
    from public.intros
    where state = 'connected'::public.intro_state
      and (sender_id = v_user or recipient_id = v_user)
  ),
  mutual_conn as (
    select
      vc.other_id as mutual_id,
      vc.updated_at as mutual_connected_at,
      case when i.sender_id = vc.other_id then i.recipient_id else i.sender_id end as target_id,
      i.updated_at as link_updated_at
    from viewer_conn vc
    join public.intros i
      on i.state = 'connected'::public.intro_state
     and (i.sender_id = vc.other_id or i.recipient_id = vc.other_id)
    where (case when i.sender_id = vc.other_id then i.recipient_id else i.sender_id end) <> v_user
  ),
  candidate_links as (
    select target_id, mutual_id, max(link_updated_at) as link_updated_at
    from mutual_conn
    group by target_id, mutual_id
  ),
  candidate_stats as (
    select
      cl.target_id,
      count(distinct cl.mutual_id)::int as mutual_count,
      (
        select cl2.mutual_id
        from candidate_links cl2
        where cl2.target_id = cl.target_id
        order by cl2.link_updated_at desc
        limit 1
      ) as top_mutual_id
    from candidate_links cl
    group by cl.target_id
  )
  select
    cs.target_id,
    tp.handle::text as target_handle,
    tp.name as target_name,
    tp.photo_url as target_photo_url,
    tp.primary_role as target_primary_role,
    tp.goal_type as target_goal_type,
    cs.mutual_count,
    cs.top_mutual_id,
    mp.name as top_mutual_name,
    mp.handle::text as top_mutual_handle
  from candidate_stats cs
  join public.profiles tp on tp.id = cs.target_id
  join public.profiles mp on mp.id = cs.top_mutual_id
  where tp.onboarded = true
    and tp.private_mode = false
    and tp.suspended_at is null
    -- #8 Exclude (a) any direct intro between viewer and target in either
    -- direction, AND (b) any pending/delivered warm_request the viewer
    -- already has about this target via any mutual.
    and not exists (
      select 1 from public.intros ix
      where (ix.sender_id = v_user    and ix.recipient_id = cs.target_id)
         or (ix.sender_id = cs.target_id and ix.recipient_id = v_user)
         or (ix.sender_id      = v_user
             and ix.warm_target_id = cs.target_id
             and ix.kind           = 'warm_request'::public.intro_kind
             and ix.state in ('pending'::public.intro_state, 'delivered'::public.intro_state))
    )
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = v_user      and b.blocked_id = cs.target_id)
         or (b.blocker_id = cs.target_id and b.blocked_id = v_user)
    )
  order by cs.mutual_count desc, tp.created_at asc
  limit v_limit;
end;
$$;

revoke all on function public.suggest_warm_intros(int) from public, anon;
grant execute on function public.suggest_warm_intros(int) to authenticated;

-- =============================================================================
-- #15: notify_intro_inserted — surface the forwarder for warm_forward intros.
-- Existing behaviour preserved for 'direct' and 'warm_request' (the latter
-- still pushes "New intro / You have a new intro to review."). For
-- 'warm_forward' we:
--   * compose a chain-aware title: "{asker} (via {mutual}) wants to connect"
--   * keep the localizable string fields under their existing keys for legacy
--     clients, while ALSO carrying via_user_id + via_user_name in the data
--     payload so modern clients render a prominent "Forwarded by Alice"
--     caption above the note.
-- =============================================================================
create or replace function public.notify_intro_inserted()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_sender_name text;
  v_via_name text;
  v_title text;
  v_body text;
  v_payload jsonb;
begin
  if new.state = 'delivered' and new.recipient_id is not null then
    if public.should_notify(
         new.recipient_id,
         'intro_received'::public.notification_kind,
         'push'::public.notification_channel
       ) then
      if new.kind = 'warm_forward'::public.intro_kind then
        -- Look up display names for the chain. Both lookups tolerate NULL
        -- gracefully via coalesce to "Someone" / "a mutual".
        select coalesce(p.name, 'Someone') into v_sender_name
          from public.profiles p where p.id = new.sender_id;
        select coalesce(p.name, 'a mutual') into v_via_name
          from public.profiles p where p.id = new.warm_target_id;

        v_title := coalesce(v_sender_name, 'Someone')
                   || ' (via ' || coalesce(v_via_name, 'a mutual')
                   || ') wants to connect';
        v_body  := 'Forwarded by ' || coalesce(v_via_name, 'a mutual')
                   || '. Tap to review.';

        v_payload := jsonb_build_object(
          'kind',          'intro_received',
          'title',         v_title,
          'body',          v_body,
          'url',           '/(app)/intros/' || new.id,
          'via_user_id',   new.warm_target_id,
          'via_user_name', v_via_name
        );
      else
        v_payload := jsonb_build_object(
          'kind',  'intro_received',
          'title', 'New intro',
          'body',  'You have a new intro to review.',
          'url',   '/(app)/intros/' || new.id
        );
      end if;

      perform public.dispatch_push(
        new.recipient_id,
        'intros',
        new.id,
        v_payload,
        p_kind            => 'intro_received',
        p_entity_id       => new.id,
        p_conversation_id => new.conversation_id
      );
    end if;
  end if;
  return new;
end;
$$;

-- =============================================================================
-- Summary
-- =============================================================================
-- #3  accept_intro now refuses warm_request kind (P0001 / 22023 'wrong intro kind').
-- #7  send_warm_request enforces one outstanding warm_request per (asker, target).
-- #8  suggest_warm_intros NOT-EXISTS now also excludes pending/delivered
--     warm_request rows by warm_target_id.
-- #14 decline_intro on warm_request transitions state without stamping declined_at.
-- #15 notify_intro_inserted composes a chain-aware push title for warm_forward
--     intros and includes via_user_id + via_user_name in the legacy payload so
--     the client can render "Forwarded by {name}" prominently.
