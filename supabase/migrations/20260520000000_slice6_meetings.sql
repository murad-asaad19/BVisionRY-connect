-- Slice 6: meetings — proposals + feedback + extend messages

create type public.meeting_state as enum ('proposed', 'confirmed', 'declined', 'cancelled');
create type public.meeting_feedback_rating as enum ('positive', 'neutral', 'negative');
create type public.message_kind as enum ('text', 'meeting');

create table public.meeting_proposals (
  id                uuid primary key default gen_random_uuid(),
  conversation_id   uuid not null references public.conversations(id) on delete cascade,
  proposed_by_id    uuid references public.profiles(id) on delete set null,
  slots             timestamptz[] not null,
  confirmed_slot    timestamptz,
  duration_minutes  integer not null default 30,
  meeting_url       text,
  state             public.meeting_state not null default 'proposed',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  constraint mp_duration_rng check (duration_minutes between 15 and 240),
  constraint mp_slots_count check (array_length(slots, 1) between 1 and 3),
  constraint mp_url_https check (meeting_url is null or meeting_url like 'https://%'),
  constraint mp_confirmed_slot_in_slots check (
    confirmed_slot is null or confirmed_slot = any (slots)
  )
);

create index meeting_proposals_conversation_idx
  on public.meeting_proposals (conversation_id, created_at desc);
create index meeting_proposals_proposed_by_idx
  on public.meeting_proposals (proposed_by_id);

create trigger meeting_proposals_set_updated_at
  before update on public.meeting_proposals
  for each row execute function extensions.moddatetime(updated_at);

alter table public.meeting_proposals enable row level security;

create policy meeting_proposals_select_participant on public.meeting_proposals
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = meeting_proposals.conversation_id
        and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
    )
  );

create table public.meeting_feedback (
  id         uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references public.meeting_proposals(id) on delete cascade,
  rater_id   uuid not null references public.profiles(id) on delete cascade,
  rating     public.meeting_feedback_rating not null,
  note       text,
  created_at timestamptz not null default now(),
  unique (meeting_id, rater_id),
  constraint mf_note_len check (note is null or char_length(note) <= 1000)
);

create index mf_meeting_idx on public.meeting_feedback (meeting_id);
create index mf_rater_idx   on public.meeting_feedback (rater_id);

alter table public.meeting_feedback enable row level security;

create policy mf_select_self on public.meeting_feedback
  for select using (rater_id = auth.uid());

alter table public.messages
  add column kind                public.message_kind not null default 'text',
  add column meeting_proposal_id uuid references public.meeting_proposals(id) on delete set null;

create index messages_meeting_proposal_idx
  on public.messages (meeting_proposal_id) where meeting_proposal_id is not null;

alter table public.messages drop constraint messages_body_len;
alter table public.messages alter column body drop not null;

alter table public.messages
  add constraint messages_kind_payload check (
       (kind = 'text'::public.message_kind
         and body is not null
         and char_length(body) between 1 and 4000
         and meeting_proposal_id is null)
    or (kind = 'meeting'::public.message_kind
         and meeting_proposal_id is not null)
  );

do $$
begin
  alter publication supabase_realtime add table public.meeting_proposals;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

create or replace function public.propose_meeting(
  p_conversation_id uuid,
  p_slots           timestamptz[],
  p_duration_minutes int default 30,
  p_meeting_url      text default null
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
    conversation_id, proposed_by_id, slots, duration_minutes, meeting_url
  ) values (
    p_conversation_id, v_caller, p_slots, p_duration_minutes, p_meeting_url
  )
  returning * into v_proposal;

  insert into public.messages (conversation_id, sender_id, kind, meeting_proposal_id)
  values (p_conversation_id, v_caller, 'meeting', v_proposal.id);

  return v_proposal;
end;
$$;
grant execute on function public.propose_meeting(uuid, timestamptz[], int, text) to authenticated;

create or replace function public.confirm_meeting(p_meeting_id uuid, p_slot timestamptz)
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
  select * into v_proposal from public.meeting_proposals where id = p_meeting_id for update;
  if not found then raise exception 'meeting not found' using errcode='P0002'; end if;
  if not exists (
    select 1 from public.conversations c
    where c.id = v_proposal.conversation_id
      and (c.participant_a_id = v_caller or c.participant_b_id = v_caller)
  ) then raise exception 'not a participant' using errcode='42501'; end if;
  if v_proposal.proposed_by_id = v_caller then
    raise exception 'proposer cannot confirm their own meeting' using errcode='42501';
  end if;
  if v_proposal.state <> 'proposed'::public.meeting_state then
    raise exception 'meeting not in proposed state' using errcode='22023';
  end if;
  if not (p_slot = any (v_proposal.slots)) then
    raise exception 'slot not in proposed slots' using errcode='22023';
  end if;

  update public.meeting_proposals
  set confirmed_slot = p_slot, state = 'confirmed'::public.meeting_state
  where id = p_meeting_id
  returning * into v_proposal;
  return v_proposal;
end;
$$;
grant execute on function public.confirm_meeting(uuid, timestamptz) to authenticated;

create or replace function public.decline_meeting(p_meeting_id uuid)
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
  select * into v_proposal from public.meeting_proposals where id = p_meeting_id for update;
  if not found then raise exception 'meeting not found' using errcode='P0002'; end if;
  if not exists (
    select 1 from public.conversations c
    where c.id = v_proposal.conversation_id
      and (c.participant_a_id = v_caller or c.participant_b_id = v_caller)
  ) then raise exception 'not a participant' using errcode='42501'; end if;
  if v_proposal.proposed_by_id = v_caller then
    raise exception 'proposer cannot decline their own meeting' using errcode='42501';
  end if;
  if v_proposal.state <> 'proposed'::public.meeting_state then
    raise exception 'meeting not in proposed state' using errcode='22023';
  end if;

  update public.meeting_proposals
  set state = 'declined'::public.meeting_state
  where id = p_meeting_id
  returning * into v_proposal;
  return v_proposal;
end;
$$;
grant execute on function public.decline_meeting(uuid) to authenticated;

create or replace function public.submit_meeting_feedback(
  p_meeting_id uuid,
  p_rating     public.meeting_feedback_rating,
  p_note       text default null
)
returns public.meeting_feedback
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_proposal public.meeting_proposals;
  v_fb public.meeting_feedback;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if p_note is not null and char_length(p_note) > 1000 then
    raise exception 'note too long' using errcode='22023';
  end if;
  select * into v_proposal from public.meeting_proposals where id = p_meeting_id;
  if not found then raise exception 'meeting not found' using errcode='P0002'; end if;
  if v_proposal.state <> 'confirmed'::public.meeting_state then
    raise exception 'feedback only for confirmed meetings' using errcode='22023';
  end if;
  if not exists (
    select 1 from public.conversations c
    where c.id = v_proposal.conversation_id
      and (c.participant_a_id = v_caller or c.participant_b_id = v_caller)
  ) then raise exception 'not a participant' using errcode='42501'; end if;

  insert into public.meeting_feedback (meeting_id, rater_id, rating, note)
  values (p_meeting_id, v_caller, p_rating, p_note)
  on conflict (meeting_id, rater_id) do update
    set rating = excluded.rating, note = excluded.note
  returning * into v_fb;
  return v_fb;
end;
$$;
grant execute on function public.submit_meeting_feedback(uuid, public.meeting_feedback_rating, text) to authenticated;
