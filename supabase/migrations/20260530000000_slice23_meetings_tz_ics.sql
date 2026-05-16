-- Slice 23: meetings timezone capture for cross-TZ rendering and ICS export
alter table public.meeting_proposals
  add column timezone text;

-- Recreate propose_meeting to accept a proposer timezone (IANA name).
-- The existing slice 6 signature is (uuid, timestamptz[], int, text); drop with the exact
-- arg types so the new signature with the added p_timezone replaces it cleanly.
drop function if exists public.propose_meeting(uuid, timestamptz[], int, text);

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
  v_proposal public.meeting_proposals;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if not exists (
    select 1 from public.conversations c
    where c.id = p_conversation_id
      and (c.participant_a_id = v_caller or c.participant_b_id = v_caller)
  ) then raise exception 'not a participant' using errcode='42501'; end if;

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
grant execute on function public.propose_meeting(uuid, timestamptz[], int, text, text) to authenticated;
