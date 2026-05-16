-- Slice 24: server-side discoverable-feed search & filters via RPC.

create or replace function public.search_discoverable_profiles(
  p_query text default null,
  p_roles public.role_kind[] default null,
  p_goal_types public.goal_type[] default null,
  p_country text default null,
  p_cursor timestamptz default '9999-12-31'::timestamptz,
  p_limit int default 20
)
returns table (
  id uuid,
  handle text,
  name text,
  photo_url text,
  headline text,
  bio text,
  roles public.role_kind[],
  primary_role public.role_kind,
  city text,
  country text,
  goal_type public.goal_type,
  goal_text text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  return query
  select p.id,
         p.handle::text,
         p.name,
         p.photo_url,
         p.headline,
         p.bio,
         p.roles,
         p.primary_role,
         p.city,
         p.country,
         p.goal_type,
         p.goal_text,
         p.created_at
  from public.profiles p
  where p.onboarded = true
    and p.id <> v_user
    and p.created_at < p_cursor
    and not exists (
      select 1 from public.blocks
      where (blocker_id = v_user and blocked_id = p.id)
         or (blocker_id = p.id and blocked_id = v_user)
    )
    and (
      p_query is null or trim(p_query) = ''
      or p.handle::text ilike '%' || p_query || '%'
      or coalesce(p.name, '') ilike '%' || p_query || '%'
    )
    and (
      p_roles is null or cardinality(p_roles) = 0
      or exists (
        select 1
        from unnest(p.roles) a
        join unnest(p_roles) b on a = b
      )
    )
    and (
      p_goal_types is null or cardinality(p_goal_types) = 0
      or p.goal_type = any (p_goal_types)
    )
    and (
      p_country is null or trim(p_country) = ''
      or lower(p.country) = lower(p_country)
    )
  order by p.created_at desc
  limit p_limit;
end;
$$;

grant execute on function public.search_discoverable_profiles(
  text, public.role_kind[], public.goal_type[], text, timestamptz, integer
) to authenticated;
