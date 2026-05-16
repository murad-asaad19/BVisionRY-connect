-- Slice 17: Matching algorithm — replace random() with multi-factor score.
-- Factors: role overlap, goal complementarity, location, recency.

-- Goal complementarity matrix
create or replace function public.goals_complementary(a public.goal_type, b public.goal_type)
returns boolean
language sql immutable parallel safe
as $$
  select case
    when a = b then false
    when (a = 'hire'            and b = 'be_hired')
      or (a = 'be_hired'        and b = 'hire')
      or (a = 'invest'          and b = 'take_investment')
      or (a = 'take_investment' and b = 'invest')
      or (a = 'advise'          and b = 'find_advisor')
      or (a = 'find_advisor'    and b = 'advise') then true
    else false
  end;
$$;

-- Match score: 0..N integer.
create or replace function public.match_score(p_self uuid, p_other uuid)
returns integer
language plpgsql stable
set search_path = public, extensions
as $$
declare
  s_roles   public.role_kind[];
  o_roles   public.role_kind[];
  s_goal    public.goal_type;
  o_goal    public.goal_type;
  s_city    text;
  s_country text;
  o_city    text;
  o_country text;
  o_created timestamptz;
  v_score   integer := 0;
  v_overlap integer;
begin
  select roles, goal_type, city, country
    into s_roles, s_goal, s_city, s_country
  from public.profiles where id = p_self;

  select roles, goal_type, city, country, created_at
    into o_roles, o_goal, o_city, o_country, o_created
  from public.profiles where id = p_other;

  if o_created is null then return 0; end if;

  -- Role overlap (2 points per overlapping role kind).
  -- Postgres has no native array intersect for non-int arrays; use unnest+join.
  v_overlap := (
    select count(*)::integer
    from unnest(s_roles) a
    join unnest(o_roles) b on a = b
  );
  v_score := v_score + coalesce(v_overlap, 0) * 2;

  -- Goal complementarity (4) or same goal (1)
  if s_goal is not null and o_goal is not null then
    if public.goals_complementary(s_goal, o_goal) then
      v_score := v_score + 4;
    elsif s_goal = o_goal then
      v_score := v_score + 1;
    end if;
  end if;

  -- Location
  if s_city is not null and o_city is not null
     and lower(trim(s_city)) = lower(trim(o_city)) then
    v_score := v_score + 3;
  end if;
  if s_country is not null and o_country is not null
     and lower(trim(s_country)) = lower(trim(o_country)) then
    v_score := v_score + 1;
  end if;

  -- Recency boost: brand new profiles surface to existing users
  if o_created >= now() - interval '1 hour' then
    v_score := v_score + 5;
  elsif o_created >= now() - interval '24 hours' then
    v_score := v_score + 3;
  elsif o_created >= now() - interval '7 days' then
    v_score := v_score + 1;
  end if;

  return v_score;
end;
$$;

-- Human-readable reason
create or replace function public.match_reason_for(p_self uuid, p_other uuid)
returns text
language plpgsql stable
set search_path = public, extensions
as $$
declare
  s_goal    public.goal_type;
  o_goal    public.goal_type;
  s_roles   public.role_kind[];
  o_roles   public.role_kind[];
  s_city    text;
  o_city    text;
  o_created timestamptz;
  v_overlap integer;
begin
  select roles, goal_type, city into s_roles, s_goal, s_city
    from public.profiles where id = p_self;
  select roles, goal_type, city, created_at into o_roles, o_goal, o_city, o_created
    from public.profiles where id = p_other;

  if s_goal is not null and o_goal is not null and public.goals_complementary(s_goal, o_goal) then
    return 'Complementary goals';
  end if;

  v_overlap := (
    select count(*)::integer
    from unnest(s_roles) a
    join unnest(o_roles) b on a = b
  );
  if coalesce(v_overlap, 0) > 0 then
    return 'Shared role';
  end if;

  if s_city is not null and o_city is not null
     and lower(trim(s_city)) = lower(trim(o_city)) then
    return 'Same city';
  end if;

  if o_created is not null and o_created >= now() - interval '24 hours' then
    return 'New on Connect';
  end if;

  return 'Daily pick';
end;
$$;

-- Updated get_daily_matches: score-ordered insert with random tiebreaker
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
    select v_user_id, p.id, p_for_date, public.match_reason_for(v_user_id, p.id)
    from public.profiles p
    where p.onboarded = true
      and p.id <> v_user_id
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
  select * from public.daily_matches
  where user_id = v_user_id and for_date_local = p_for_date
  order by created_at;
end;
$$;
