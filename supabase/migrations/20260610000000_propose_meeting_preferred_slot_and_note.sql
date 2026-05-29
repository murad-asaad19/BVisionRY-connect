-- Persist the proposer's recommended slot and freeform note on
-- public.meeting_proposals so the recipient's confirm UI can highlight the
-- recommendation and render the note alongside the slot grid.
--
-- The Flutter compose sheet already collects both fields and forwards them
-- on propose_meeting; without this migration, PostgREST rejects the call
-- with PGRST202 (no matching function signature) and the proposal never
-- reaches the server.

alter table public.meeting_proposals
  add column preferred_slot_index integer,
  add column note text;

alter table public.meeting_proposals
  add constraint mp_preferred_slot_index_range check (
    preferred_slot_index is null
      or (preferred_slot_index >= 0
          and preferred_slot_index < coalesce(array_length(slots, 1), 0))
  );

alter table public.meeting_proposals
  add constraint mp_note_len check (
    note is null or char_length(note) between 1 and 1000
  );

-- Replace the 5-arg signature with a 7-arg one. Drop the precise old types
-- explicitly so the new function REPLACES rather than overloads (Postgres
-- considers default args ambiguous across overloads).
drop function if exists public.propose_meeting(uuid, timestamptz[], int, text, text);

create or replace function public.propose_meeting(
  p_conversation_id      uuid,
  p_slots                timestamptz[],
  p_duration_minutes     int  default 30,
  p_meeting_url          text default null,
  p_timezone             text default null,
  p_preferred_slot_index int  default null,
  p_note                 text default null
)
returns public.meeting_proposals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller       uuid := auth.uid();
  v_other        uuid;
  v_proposal     public.meeting_proposals;
  v_trimmed_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if v_caller is null then
    raise exception 'unauthenticated' using errcode='28000';
  end if;

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
    conversation_id, proposed_by_id, slots, duration_minutes,
    meeting_url, timezone, preferred_slot_index, note
  ) values (
    p_conversation_id, v_caller, p_slots, p_duration_minutes,
    p_meeting_url, p_timezone, p_preferred_slot_index, v_trimmed_note
  )
  returning * into v_proposal;

  insert into public.messages (conversation_id, sender_id, kind, meeting_proposal_id)
  values (p_conversation_id, v_caller, 'meeting', v_proposal.id);

  return v_proposal;
end;
$$;

grant execute on function public.propose_meeting(
  uuid, timestamptz[], int, text, text, int, text
) to authenticated;
