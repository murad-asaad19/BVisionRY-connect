-- Slice 4: intros — send/accept/decline

create type public.intro_state as enum (
  'delivered', 'accepted', 'declined', 'expired', 'connected'
);

create table public.intros (
  id              uuid primary key default gen_random_uuid(),
  sender_id       uuid references public.profiles(id) on delete set null,
  recipient_id    uuid references public.profiles(id) on delete set null,
  note            text not null,
  state           public.intro_state not null default 'delivered',
  conversation_id uuid,
  expires_at      timestamptz not null default (now() + interval '14 days'),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint intros_no_self check (
    sender_id is null or recipient_id is null or sender_id <> recipient_id
  ),
  constraint intros_note_len check (
    char_length(note) between 80 and 400
  )
);

create index intros_sender_state_idx
  on public.intros (sender_id, state, created_at desc);
create index intros_recipient_state_idx
  on public.intros (recipient_id, state, created_at desc);
create unique index intros_active_pair_uq
  on public.intros (sender_id, recipient_id)
  where state = 'delivered';

create trigger intros_set_updated_at
  before update on public.intros
  for each row execute function extensions.moddatetime(updated_at);

alter table public.intros enable row level security;

create policy intros_select_party on public.intros
  for select using (
    auth.uid() = sender_id or auth.uid() = recipient_id
  );

-- send_intro
create or replace function public.send_intro(p_recipient_id uuid, p_note text)
returns public.intros
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender uuid := auth.uid();
  v_intro public.intros;
begin
  if v_sender is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  if v_sender = p_recipient_id then raise exception 'cannot intro to self' using errcode = '22023'; end if;
  if char_length(p_note) < 80 or char_length(p_note) > 400 then
    raise exception 'note must be 80-400 characters' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles where id = p_recipient_id and onboarded = true) then
    raise exception 'recipient not available' using errcode = 'P0002';
  end if;
  insert into public.intros (sender_id, recipient_id, note)
  values (v_sender, p_recipient_id, p_note)
  returning * into v_intro;
  return v_intro;
end;
$$;
grant execute on function public.send_intro(uuid, text) to authenticated;

-- accept_intro
create or replace function public.accept_intro(p_intro_id uuid)
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
    raise exception 'only the recipient can accept' using errcode = '42501';
  end if;
  if v_intro.state <> 'delivered'::public.intro_state then
    raise exception 'intro not in delivered state' using errcode = '22023';
  end if;
  if v_intro.expires_at < now() then
    raise exception 'intro has expired' using errcode = '22023';
  end if;
  update public.intros set state = 'accepted'::public.intro_state
   where id = p_intro_id returning * into v_intro;
  return v_intro;
end;
$$;
grant execute on function public.accept_intro(uuid) to authenticated;

-- decline_intro
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
  update public.intros set state = 'declined'::public.intro_state
   where id = p_intro_id returning * into v_intro;
  return v_intro;
end;
$$;
grant execute on function public.decline_intro(uuid) to authenticated;
