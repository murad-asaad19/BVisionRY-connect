-- Wave 6: security hardening.
--
-- This migration plugs a cluster of authorization bugs surfaced in the
-- post-merge audit of the password-auth branch. None of the issues touch
-- the on-disk schema; all fixes are SECURITY DEFINER function rewrites,
-- a column-level grant tighten, and a scheduled cron job addition.
--
--   1. CRITICAL — dispatch_push / dispatch_transcription were callable by
--      every authenticated user. Either is an internal trigger helper.
--      Revoke EXECUTE from PUBLIC so the function bodies remain callable
--      only by the trigger/definer owners (postgres) and by other
--      SECURITY DEFINER functions that perform() them.
--
--   2. CRITICAL — submit_meeting_review accepted any (meeting_id, outcome)
--      tuple from any authenticated user. Add (a) participant check via
--      the meeting's conversation and (b) meeting state must be
--      'confirmed'. Both raise SQLSTATE 42501 otherwise.
--
--   3. CRITICAL — register_device_token's on-conflict path silently
--      reassigned a token to the caller. Attacker who captures a victim's
--      FCM token (logs, MITM, malicious app, etc.) could hijack push
--      delivery by re-registering it on their own account. Reject the
--      registration when the token is already owned by another live user.
--
--   5. HIGH — mark_conversation_read short-circuited on
--      read_receipts_enabled=false, leaving the reader's own unread badge
--      stuck. Always upsert conversation_reads; future peer-visible read
--      receipts (none exist today) must gate on the preference.
--
--   6. HIGH — daily_matches let authenticated PostgREST callers UPDATE
--      arbitrary columns (notably match_reason). Only mark_match_viewed
--      (SECURITY DEFINER) needs write access. Revoke direct UPDATE.
--
--   7. HIGH — propose_meeting and the messages_insert_participant RLS
--      policy didn't check the blocks table. Either side can now reject
--      the action with SQLSTATE 42501 / policy violation.
--
--   9. HIGH — chat-media bucket has no orphan sweep. Register a daily
--      cron job that deletes storage objects older than 24h with no
--      backing message row.
--
-- Item 4 (messages.sender_id NOT NULL + partial index rebuild) is split
-- into the companion file 20260607010000_schema_tighten.sql because it
-- mutates table schema, not behaviour, and the two concerns deserve
-- independent rollback boundaries.
--
-- Item 8 (daily_matches blocked-target persistence) was already covered
-- by the SELECT-time blocks filter in
-- 20260606090000_discovery_fixes.sql — no fix required.

-- =============================================================================
-- #1 Revoke PUBLIC execute on dispatch_* helpers
-- =============================================================================
-- Canonical 7-arg dispatch_push from 20260606150000_dispatch_push_payload.sql.
revoke execute on function public.dispatch_push(
  uuid, text, uuid, jsonb, text, uuid, uuid
) from public;

revoke execute on function public.dispatch_transcription(uuid) from public;

-- =============================================================================
-- #2 submit_meeting_review: add participant + confirmed-state gates
-- =============================================================================
-- Original signature is (uuid, text, text) from 20260604000000_audit_fixes.sql.
-- We CREATE OR REPLACE preserving the signature exactly so the existing
-- grant/RLS surface is untouched.
create or replace function public.submit_meeting_review(
  p_meeting_id uuid,
  p_outcome    text,
  p_note       text
) returns public.meeting_reviews
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row  public.meeting_reviews;
  v_is_participant boolean;
  v_state public.meeting_state;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_outcome not in ('useful', 'not_useful', 'no_show') then
    raise exception 'outcome must be useful, not_useful, or no_show' using errcode = '22023';
  end if;

  -- Caller must be a participant of the meeting's conversation, and the
  -- meeting must have been confirmed. Both checks share the same join.
  select
    (c.participant_a_id = v_user or c.participant_b_id = v_user),
    mp.state
    into v_is_participant, v_state
    from public.meeting_proposals mp
    join public.conversations c on c.id = mp.conversation_id
   where mp.id = p_meeting_id;

  if not found then
    raise exception 'meeting not found' using errcode = 'P0002';
  end if;
  if not coalesce(v_is_participant, false) then
    raise exception 'not a meeting participant' using errcode = '42501';
  end if;
  if v_state is distinct from 'confirmed'::public.meeting_state then
    raise exception 'meeting not confirmed' using errcode = '42501';
  end if;

  insert into public.meeting_reviews (meeting_id, reviewer_id, outcome, note)
  values (p_meeting_id, v_user, p_outcome, nullif(trim(coalesce(p_note, '')), ''))
  on conflict (meeting_id, reviewer_id) do update
    set outcome = excluded.outcome,
        note    = excluded.note
  returning * into v_row;
  return v_row;
end;
$$;

-- =============================================================================
-- #3 register_device_token: reject hijack attempts
-- =============================================================================
-- Signature is (text, public.device_platform) from
-- 20260606120000_device_tokens_unique.sql. Preserved verbatim.
--
-- Behaviour change: if the token is already bound to a *different* live
-- (non-revoked) user, raise SQLSTATE 28000. Two legitimate reassignment
-- paths still work:
--   (a) the same user re-registering after sign-out (token row was revoked
--       or matches v_user already → upsert proceeds).
--   (b) the previous owner's row is already revoked (sign-out before
--       handoff to a new account on the same device) → upsert proceeds.
create or replace function public.register_device_token(
  p_token text,
  p_platform public.device_platform
)
returns public.device_tokens
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row public.device_tokens;
  v_existing_user uuid;
  v_existing_revoked timestamptz;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_token is null or length(p_token) < 16 then
    raise exception 'invalid token' using errcode = '22023';
  end if;

  -- Hijack check: only reject if a live row owned by another user exists.
  select user_id, revoked_at
    into v_existing_user, v_existing_revoked
    from public.device_tokens
   where token = p_token;

  if v_existing_user is not null
     and v_existing_user <> v_user
     and v_existing_revoked is null then
    raise exception 'token already registered to another account'
      using errcode = '28000';
  end if;

  insert into public.device_tokens (user_id, token, platform)
  values (v_user, p_token, p_platform)
  on conflict (token) do update
    set user_id      = excluded.user_id,
        platform     = excluded.platform,
        last_seen_at = now(),
        revoked_at   = null
  returning * into v_row;

  return v_row;
end;
$$;

-- =============================================================================
-- #5 mark_conversation_read: always track reader unread state
-- =============================================================================
-- Previously short-circuited on read_receipts_enabled=false, freezing the
-- caller's own unread counter. The realtime/peer-visible read-receipt
-- channel does not exist yet, so the preference gate has nothing to gate;
-- when it lands, callers of the broadcast helper must check the flag.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  -- Always upsert: this row backs the caller's own unread badge in
  -- list_conversation_unread(). Peer-visible read receipts are a separate
  -- (not-yet-implemented) feature; that broadcast path must consult
  -- profiles.read_receipts_enabled before emitting anything cross-user.
  insert into public.conversation_reads (user_id, conversation_id, last_read_at)
  values (v_user, p_conversation_id, now())
  on conflict (user_id, conversation_id) do update set last_read_at = now();
end;
$$;

-- =============================================================================
-- #6 daily_matches: revoke direct UPDATE from authenticated
-- =============================================================================
-- mark_match_viewed (SECURITY DEFINER, owner=postgres) bypasses the role
-- grant via SET ROLE / definer semantics, so the revoke does not affect
-- the legitimate write path. The RLS UPDATE policy
-- daily_matches_update_own remains in place but is now effectively dead
-- for non-definer roles, which is the desired posture.
revoke update on public.daily_matches from authenticated;

-- =============================================================================
-- #7a propose_meeting: reject when either party blocked the other
-- =============================================================================
-- Original signature is (uuid, timestamptz[], int, text, text) from
-- 20260530000000_slice23_meetings_tz_ics.sql. Preserved verbatim.
create or replace function public.propose_meeting(
  p_conversation_id  uuid,
  p_slots            timestamptz[],
  p_duration_minutes int default 30,
  p_meeting_url      text default null,
  p_timezone         text default null
)
returns public.meeting_proposals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_other  uuid;
  v_proposal public.meeting_proposals;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  -- Participant check + capture the counterparty for the block test.
  select case
           when c.participant_a_id = v_caller then c.participant_b_id
           when c.participant_b_id = v_caller then c.participant_a_id
           else null
         end
    into v_other
    from public.conversations c
   where c.id = p_conversation_id;

  if v_other is null then
    raise exception 'not a participant' using errcode='42501';
  end if;

  -- Block check: either side having blocked the other voids the proposal.
  if exists (
    select 1 from public.blocks
    where (blocker_id = v_caller and blocked_id = v_other)
       or (blocker_id = v_other  and blocked_id = v_caller)
  ) then
    raise exception 'blocked' using errcode='42501';
  end if;

  insert into public.meeting_proposals (
    conversation_id, proposed_by_id, slots, duration_minutes, meeting_url, timezone
  ) values (
    p_conversation_id, v_caller, p_slots, p_duration_minutes, p_meeting_url, p_timezone
  )
  returning * into v_proposal;

  insert into public.messages (conversation_id, sender_id, kind, meeting_proposal_id)
  values (p_conversation_id, v_caller, 'meeting', v_proposal.id);

  return v_proposal;
end;
$$;

-- =============================================================================
-- #7b messages_insert_participant: tighten WITH CHECK to include block test
-- =============================================================================
-- Latest definition lives in 20260606000000_rls_hardening.sql (text-only
-- restriction). We re-add the blocks-not-exists predicate; participants
-- are derived from the conversation row reused from that check.
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
        and not exists (
          select 1 from public.blocks b
          where (b.blocker_id = c.participant_a_id and b.blocked_id = c.participant_b_id)
             or (b.blocker_id = c.participant_b_id and b.blocked_id = c.participant_a_id)
        )
    )
  );

-- =============================================================================
-- #9 chat-media orphan storage cleanup (daily 04:00 UTC)
-- =============================================================================
-- Registered alongside the Wave-5 scheduled jobs. Skipped if a job of the
-- same name already exists. The DELETE is bounded by created_at < now() -
-- 24h so in-flight uploads from clients that haven't yet INSERTed the
-- backing public.messages row are safe.
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'chat-media-orphan-sweep') then
    perform cron.schedule(
      'chat-media-orphan-sweep',
      '0 4 * * *',
      $job$
        delete from storage.objects
        where bucket_id = 'chat-media'
          and created_at < now() - interval '24 hours'
          and not exists (
            select 1 from public.messages m
            where m.media_path = storage.objects.name
          );
      $job$
    );
  end if;
end
$$;
