-- RR2 follow-ups to Wave-6 security hardening (20260607000000).
--
-- Closes four gaps surfaced by the post-merge review:
--
--   1. CRITICAL — the dispatch_push(uuid, text, uuid, jsonb) 4-arg overload
--      (from 20260521000000 / 20260606010000) survived Wave-6's revoke, which
--      only targeted the 7-arg variant. Postgres treats different arg counts
--      as distinct functions, so the 4-arg form remained PUBLIC-callable and
--      could still be invoked by any authenticated user to poison push_log
--      and abuse pg_net. No callers remain after Wave-5 swapped every trigger
--      to the 7-arg signature, so the safe fix is to DROP it outright.
--
--   2. HIGH — mark_conversation_read (Wave-6) removed the read_receipts
--      short-circuit but did not re-add a participant check, allowing any
--      authenticated user to INSERT a conversation_reads row for any
--      conversation UUID. The PK prevents amplification but junk rows
--      persist. Re-add a participant gate before the upsert.
--
--   3. HIGH — submit_meeting_review (Wave-6) checks state='confirmed' but
--      does not check that the meeting has actually ended. A confirmed
--      meeting still in the future could be reviewed via direct RPC even
--      though the UI never surfaces it. Add a
--      `confirmed_slot + duration < now()` gate to match the cutoff used
--      by pending_meeting_reviews.
--
--   4. SCHEMA — add 'processing' to public.transcript_status so the
--      transcribe-voice edge function can atomically claim a row before
--      calling Whisper (dedup against duplicate webhook fires).

-- =============================================================================
-- (1) transcript_status: add 'processing' label
-- =============================================================================
-- PG 12+ allows ADD VALUE inside a transaction; the only restriction is that
-- the new label cannot be USED in the same transaction. Nothing else in this
-- migration references 'processing' (the edge function reads/writes it from
-- outside), so no commit gymnastics are needed.
alter type public.transcript_status add value if not exists 'processing';

-- =============================================================================
-- (2) Drop orphaned 4-arg dispatch_push overload
-- =============================================================================
-- Wave-6 revoked execute on the 7-arg form
-- (uuid, text, uuid, jsonb, text, uuid, uuid) but the 4-arg form
-- (uuid, text, uuid, jsonb) from 20260521000000 / 20260606010000 is a
-- separate function and was left grantable to PUBLIC. Wave-5
-- (20260606150000) rewrote every trigger to call the 7-arg form, so the
-- 4-arg form has no remaining in-tree callers and can be dropped outright.
drop function if exists public.dispatch_push(uuid, text, uuid, jsonb);

-- =============================================================================
-- (3) mark_conversation_read: gate the upsert on participant membership
-- =============================================================================
-- Preserves the Wave-6 signature and behaviour (always upsert, no
-- read_receipts short-circuit) and only adds the participant check. The
-- conversation_reads PK already prevents amplification, but without this
-- guard any authenticated user can INSERT a row for any conversation UUID.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  -- Participant guard: caller must be on one side of the conversation.
  -- Without this, the upsert below would accept arbitrary conversation IDs
  -- (the PK only collapses duplicates, it doesn't authorize the write).
  if not exists (
    select 1 from public.conversations
    where id = p_conversation_id
      and (participant_a_id = v_user or participant_b_id = v_user)
  ) then
    raise exception 'Not a participant' using errcode = '42501';
  end if;

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
-- (4) submit_meeting_review: add post-meeting-end time gate
-- =============================================================================
-- Wave-6 already gates on (a) participant and (b) state='confirmed'. RR2
-- adds (c) the meeting must have ended (confirmed_slot + duration < now()).
-- Without this, a confirmed but still-future meeting could be reviewed via
-- direct RPC even though pending_meeting_reviews never surfaces it. We
-- extend the existing join to pull confirmed_slot / duration_minutes and
-- check after the state check (the time check is meaningless without a
-- confirmed slot).
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
  v_confirmed_slot timestamptz;
  v_duration int;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_outcome not in ('useful', 'not_useful', 'no_show') then
    raise exception 'outcome must be useful, not_useful, or no_show' using errcode = '22023';
  end if;

  -- Caller must be a participant, the meeting must have been confirmed,
  -- and the meeting must have actually ended. All checks share one join.
  select
    (c.participant_a_id = v_user or c.participant_b_id = v_user),
    mp.state,
    mp.confirmed_slot,
    mp.duration_minutes
    into v_is_participant, v_state, v_confirmed_slot, v_duration
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
  -- confirmed_slot is guaranteed non-null by the confirm path, but guard
  -- anyway so a manual UPDATE setting state='confirmed' without a slot
  -- can't slip through.
  if v_confirmed_slot is null
     or v_confirmed_slot + (v_duration || ' minutes')::interval > now() then
    raise exception 'Meeting has not yet ended' using errcode = '42501';
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
