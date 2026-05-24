-- Discovery fixes:
--   * get_daily_matches widens the return shape to include the joined profile
--     fields the mobile UI actually renders (kills the N+1 useQueries loop).
--   * Trailing select re-applies private_mode / suspended_at / blocks filters
--     so picks inserted on an earlier day that became invalid in the meantime
--     are not returned. The insert-once-per-day shape is preserved.

-- The return type changes from `setof public.daily_matches` to `returns table(...)`,
-- which Postgres rejects under `create or replace`. Drop first, then recreate.
drop function if exists public.get_daily_matches(date);

create or replace function public.get_daily_matches(p_for_date date default current_date)
returns table (
  id              uuid,
  pick_user_id    uuid,
  match_reason    text,
  for_date_local  date,
  viewed_at       timestamptz,
  created_at      timestamptz,
  name            text,
  handle          text,
  photo_url       text,
  headline        text,
  bio             text,
  city            text,
  country         text,
  primary_role    public.role_kind,
  roles           public.role_kind[],
  goal_type       public.goal_type
)
language plpgsql security definer set search_path = public, extensions
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
    select v_user_id, p.id, p_for_date, public.match_reason_for(v_user_id, p.id)
    from public.profiles p
    where p.onboarded = true
      and p.id <> v_user_id
      and not p.private_mode
      and p.suspended_at is null
      and not exists (
        select 1 from public.blocks
        where (blocker_id = v_user_id and blocked_id = p.id)
           or (blocker_id = p.id and blocked_id = v_user_id)
      )
    order by public.match_score(v_user_id, p.id) desc, p.created_at desc, random()
    limit 5
    on conflict (user_id, pick_user_id, for_date_local) do nothing;
  end if;

  return query
  select
    dm.id,
    dm.pick_user_id,
    dm.match_reason,
    dm.for_date_local,
    dm.viewed_at,
    dm.created_at,
    p.name,
    p.handle::text,
    p.photo_url,
    p.headline,
    p.bio,
    p.city,
    p.country,
    p.primary_role,
    p.roles,
    p.goal_type
  from public.daily_matches dm
  join public.profiles p on p.id = dm.pick_user_id
  where dm.user_id = v_user_id
    and dm.for_date_local = p_for_date
    and p.onboarded = true
    and not p.private_mode
    and p.suspended_at is null
    and not exists (
      select 1 from public.blocks
      where (blocker_id = v_user_id and blocked_id = p.id)
         or (blocker_id = p.id and blocked_id = v_user_id)
    )
  order by dm.created_at;
end;
$$;

grant execute on function public.get_daily_matches(date) to authenticated;
