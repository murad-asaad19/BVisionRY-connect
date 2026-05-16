-- Slice 3: discovery surface — daily_matches table + RPCs + discoverable profile policy

create table public.daily_matches (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.profiles(id) on delete cascade,
  pick_user_id    uuid not null references public.profiles(id) on delete cascade,
  match_reason    text not null default 'Daily pick',
  for_date_local  date not null,
  viewed_at       timestamptz,
  created_at      timestamptz not null default now(),
  constraint daily_matches_no_self check (user_id <> pick_user_id)
);

create unique index daily_matches_user_pick_date_uq
  on public.daily_matches (user_id, pick_user_id, for_date_local);
create index daily_matches_user_date_idx
  on public.daily_matches (user_id, for_date_local desc);

alter table public.daily_matches enable row level security;

create policy daily_matches_select_own on public.daily_matches
  for select using (user_id = auth.uid());
create policy daily_matches_update_own on public.daily_matches
  for update using (user_id = auth.uid());

-- New policy on profiles: any authenticated user can see any onboarded profile
create policy profiles_select_discoverable on public.profiles
  for select using (onboarded = true);

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
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select count(*) into v_existing
  from public.daily_matches
  where user_id = v_user_id and for_date_local = p_for_date;

  if v_existing = 0 then
    insert into public.daily_matches (user_id, pick_user_id, for_date_local, match_reason)
    select v_user_id, p.id, p_for_date, 'Daily pick'
    from public.profiles p
    where p.onboarded = true and p.id <> v_user_id
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
grant execute on function public.get_daily_matches(date) to authenticated;

create or replace function public.mark_match_viewed(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.daily_matches
  set viewed_at = now()
  where id = p_match_id and user_id = auth.uid() and viewed_at is null;
end;
$$;
grant execute on function public.mark_match_viewed(uuid) to authenticated;
