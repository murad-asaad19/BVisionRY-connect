-- Slice 9: privacy — blocks + reports + RLS cross-cutting filters

create table public.blocks (
  blocker_id  uuid not null references public.profiles(id) on delete cascade,
  blocked_id  uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_no_self check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);

alter table public.blocks enable row level security;

create policy blocks_select_own on public.blocks
  for select using (blocker_id = auth.uid());

create type public.report_target_type as enum ('profile', 'message', 'intro');
create type public.report_reason as enum (
  'spam','harassment','impersonation','inappropriate','other'
);

create table public.reports (
  id           uuid primary key default gen_random_uuid(),
  reporter_id  uuid not null references public.profiles(id) on delete cascade,
  target_type  public.report_target_type not null,
  target_id    uuid not null,
  reason       public.report_reason not null,
  note         text,
  created_at   timestamptz not null default now(),
  constraint reports_note_len check (note is null or char_length(note) <= 1000)
);
create index reports_target_idx on public.reports (target_type, target_id);

alter table public.reports enable row level security;
-- No select policy = no one can read except service_role (admin path)

-- RPCs

create or replace function public.block_user(p_target uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if v_user = p_target then raise exception 'cannot block self' using errcode='22023'; end if;
  insert into public.blocks (blocker_id, blocked_id)
  values (v_user, p_target)
  on conflict do nothing;

  -- Dismiss active intros between the pair
  update public.intros
  set state = 'declined'::public.intro_state
  where state = 'delivered'::public.intro_state
    and (
      (sender_id = v_user and recipient_id = p_target)
      or (sender_id = p_target and recipient_id = v_user)
    );
end;
$$;
grant execute on function public.block_user(uuid) to authenticated;

create or replace function public.unblock_user(p_target uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  delete from public.blocks where blocker_id = v_user and blocked_id = p_target;
end;
$$;
grant execute on function public.unblock_user(uuid) to authenticated;

create or replace function public.list_blocked_users()
returns table (
  blocked_id uuid,
  handle text,
  name text,
  photo_url text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  return query
  select b.blocked_id, p.handle::text, p.name, p.photo_url, b.created_at
  from public.blocks b
  join public.profiles p on p.id = b.blocked_id
  where b.blocker_id = v_user
  order by b.created_at desc;
end;
$$;
grant execute on function public.list_blocked_users() to authenticated;

create or replace function public.report_target(
  p_target_type text,
  p_target_id uuid,
  p_reason text,
  p_note text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if p_target_type = 'profile' and p_target_id = v_user then
    raise exception 'cannot report self' using errcode='22023';
  end if;
  insert into public.reports (reporter_id, target_type, target_id, reason, note)
  values (
    v_user,
    p_target_type::public.report_target_type,
    p_target_id,
    p_reason::public.report_reason,
    p_note
  );
end;
$$;
grant execute on function public.report_target(text, uuid, text, text) to authenticated;

-- RLS updates: profiles, intros, conversations, messages

drop policy profiles_select_discoverable on public.profiles;
create policy profiles_select_discoverable on public.profiles
  for select using (
    onboarded = true
    and not exists (
      select 1 from public.blocks
      where (blocker_id = auth.uid() and blocked_id = profiles.id)
         or (blocker_id = profiles.id and blocked_id = auth.uid())
    )
  );

drop policy intros_select_party on public.intros;
create policy intros_select_party on public.intros
  for select using (
    (auth.uid() = sender_id or auth.uid() = recipient_id)
    and not exists (
      select 1 from public.blocks
      where (blocker_id = auth.uid() and (blocked_id = intros.sender_id or blocked_id = intros.recipient_id))
         or ((blocker_id = intros.sender_id or blocker_id = intros.recipient_id) and blocked_id = auth.uid())
    )
  );

drop policy conversations_select_participant on public.conversations;
create policy conversations_select_participant on public.conversations
  for select using (
    (auth.uid() = participant_a_id or auth.uid() = participant_b_id)
    and not exists (
      select 1 from public.blocks
      where (blocker_id = auth.uid() and (blocked_id = conversations.participant_a_id or blocked_id = conversations.participant_b_id))
         or ((blocker_id = conversations.participant_a_id or blocker_id = conversations.participant_b_id) and blocked_id = auth.uid())
    )
  );

-- Update get_daily_matches to skip blocked
create or replace function public.get_daily_matches(p_for_date date default current_date)
returns setof public.daily_matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing int;
begin
  if v_user_id is null then raise exception 'not authenticated'; end if;

  select count(*) into v_existing
  from public.daily_matches
  where user_id = v_user_id and for_date_local = p_for_date;

  if v_existing = 0 then
    insert into public.daily_matches (user_id, pick_user_id, for_date_local, match_reason)
    select v_user_id, p.id, p_for_date, 'Daily pick'
    from public.profiles p
    where p.onboarded = true
      and p.id <> v_user_id
      and not exists (
        select 1 from public.blocks
        where (blocker_id = v_user_id and blocked_id = p.id)
           or (blocker_id = p.id and blocked_id = v_user_id)
      )
    order by random()
    limit 5
    on conflict (user_id, pick_user_id, for_date_local) do nothing;
  end if;

  return query
  select * from public.daily_matches
  where user_id = v_user_id and for_date_local = p_for_date
  order by created_at;
end;
$$;
