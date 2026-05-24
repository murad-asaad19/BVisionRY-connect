-- Meetings fixes follow-up:
--   * cancel_meeting(uuid) RPC — proposer-only state transition for in-flight
--     proposals (proposed → cancelled). Mirrors decline_meeting's shape but
--     only the proposer can call it.
--   * pending_meeting_reviews() RPC — returns confirmed meetings whose end
--     is in the past (within a 14-day review window) for which the caller
--     has not yet submitted a meeting_reviews row. Centralises the filtering
--     that PostMeetingPrompt previously did client-side, and enforces the
--     "no older than 14 days" cap referenced in PostMeetingPrompt's UI copy.

-- =============================================================================
-- cancel_meeting: proposer cancels their own in-flight proposal.
-- Only allowed while state = 'proposed'. SECURITY DEFINER so callers without
-- direct write access to meeting_proposals can still flip state via this RPC
-- (matches the slice 6 confirm/decline pattern). Returns the updated row.
-- =============================================================================
create or replace function public.cancel_meeting(p_meeting_id uuid)
returns public.meeting_proposals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller   uuid := auth.uid();
  v_proposal public.meeting_proposals;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  select * into v_proposal
    from public.meeting_proposals
   where id = p_meeting_id
   for update;
  if not found then raise exception 'meeting not found' using errcode = 'P0002'; end if;

  if v_proposal.proposed_by_id is null or v_proposal.proposed_by_id <> v_caller then
    raise exception 'only the proposer can cancel' using errcode = '42501';
  end if;

  if v_proposal.state <> 'proposed'::public.meeting_state then
    raise exception 'meeting not in proposed state' using errcode = '22023';
  end if;

  update public.meeting_proposals
     set state = 'cancelled'::public.meeting_state
   where id = p_meeting_id
   returning * into v_proposal;

  return v_proposal;
end;
$$;

grant execute on function public.cancel_meeting(uuid) to authenticated;

-- =============================================================================
-- pending_meeting_reviews: confirmed meetings the caller participated in whose
-- end time has passed (start + duration < now) and for which the caller has
-- NOT yet written a review. Caps the window at 14 days so the UI prompt
-- stops nagging about ancient meetings (the 48h note in PostMeetingPrompt is
-- a soft hint; the hard upper bound lives here).
-- Returns rows in the meeting_proposals row shape so the mobile cache can
-- reuse the existing MeetingProposalRow type.
-- =============================================================================
create or replace function public.pending_meeting_reviews()
returns setof public.meeting_proposals
language sql
stable
security definer
set search_path = public
as $$
  select mp.*
    from public.meeting_proposals mp
    join public.conversations c on c.id = mp.conversation_id
   where (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
     and mp.state = 'confirmed'::public.meeting_state
     and mp.confirmed_slot is not null
     and mp.confirmed_slot + (mp.duration_minutes || ' minutes')::interval < now()
     and mp.confirmed_slot > now() - interval '14 days'
     and not exists (
       select 1 from public.meeting_reviews mr
        where mr.meeting_id = mp.id
          and mr.reviewer_id = auth.uid()
     )
   order by mp.confirmed_slot desc
   limit 20;
$$;

grant execute on function public.pending_meeting_reviews() to authenticated;
