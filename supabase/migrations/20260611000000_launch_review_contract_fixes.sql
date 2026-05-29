-- Launch-review contract fixes: align the DB with the Flutter client contract
-- and clear several Supabase advisor findings ahead of launch.
--
-- Why this migration exists (each block is independent and idempotent):
--
--   1. profiles: add the columns the Flutter `Profile` model
--      (lib/features/profile/domain/profile.dart) already declares JSON keys
--      for — last_active_at + the builder/founder/investor role-detail
--      columns. The model round-trips these via fromJson/copyWith but had no
--      backing storage, so reads always returned null and writes would 400.
--      Column names mirror the model's @JsonKey names verbatim.
--
--   2. last_active_at stamping: a SECURITY DEFINER AFTER-INSERT trigger on
--      public.messages bumps the sender's profiles.last_active_at to now().
--      Drives the "Active this week" recency pill (Profile.isActiveThisWeek).
--      Sending a message is the cheapest reliable activity signal we already
--      persist. Single-row UPDATE keyed on PK — negligible write overhead.
--
--   3-4. get_daily_matches / search_discoverable_profiles: surface two trust
--      cues the gallery wants — `verified` (has a verified GitHub identity)
--      and `last_active_at`. Added to both the RETURNS TABLE signature and the
--      final SELECT projection only; all filters/ordering/cursor logic is
--      preserved verbatim from the live definitions.
--
--   5. get_public_profile: hide suspended users from /p/:handle by adding
--      `and p.suspended_at is null` to the WHERE clause. Mirrors the same
--      guard already present in get_daily_matches / suggest_warm_intros.
--
--   6. avatars storage: the broad "avatars-read" SELECT policy
--      (qual: bucket_id = 'avatars') let any anonymous client LIST every
--      object in the bucket (advisor: public_bucket_allows_listing). The
--      avatars bucket is public, so individual objects are still served by
--      URL regardless of RLS — we only need to stop enumeration. We replace
--      the blanket SELECT policy with an owner-scoped one (folder == uid), so
--      authenticated owners can still list their own files while anonymous /
--      cross-user LISTing is no longer granted. Public read-by-URL is
--      unaffected (public bucket); upload (insert/update) policies untouched.
--
--   7. function_search_path_mutable: pin search_path on the three remaining
--      unpinned functions. Every other hardened function in this DB uses
--      `search_path = public, extensions` (73 functions; none use ''), so we
--      match that convention rather than '' — these bodies reference
--      public.* + built-ins and rely on the goal_type enum resolving via the
--      public schema. Bodies are left untouched; only the config is set.
--
-- NOT touched here (intentionally): update_opportunity / close_opportunity
-- (client now tolerates their void return), finish_onboarding (role-detail
-- capture is a separate client task), and reports RLS (deny-by-default is
-- intended).

-- ============================================================
-- 1. profiles: new columns backing the Flutter Profile model
-- ============================================================
alter table public.profiles add column if not exists last_active_at    timestamptz;

-- Builder role details
alter table public.profiles add column if not exists builder_discipline text;
alter table public.profiles add column if not exists builder_seniority  text;
alter table public.profiles add column if not exists builder_skills     text[] not null default '{}';
alter table public.profiles add column if not exists builder_open_to    text[] not null default '{}';
alter table public.profiles add column if not exists builder_rate_band  text;

-- Founder role details
alter table public.profiles add column if not exists founder_stage      text;
alter table public.profiles add column if not exists founder_sector     text;
alter table public.profiles add column if not exists founder_funding    text;
alter table public.profiles add column if not exists founder_hiring     boolean;

-- Investor role details
alter table public.profiles add column if not exists investor_type       text;
alter table public.profiles add column if not exists investor_check_size text;
alter table public.profiles add column if not exists investor_sectors    text[] not null default '{}';
alter table public.profiles add column if not exists investor_stage      text;

-- ============================================================
-- 2. last_active_at stamping (AFTER INSERT on messages)
--    messages sender column is `sender_id` (verified against schema).
--    SECURITY DEFINER so the stamp succeeds regardless of the sender's
--    RLS on profiles; search_path pinned to match DB convention.
-- ============================================================
create or replace function public.stamp_sender_last_active()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  update public.profiles
  set last_active_at = now()
  where id = new.sender_id;
  return new;
end;
$$;

revoke all on function public.stamp_sender_last_active() from public, anon;

drop trigger if exists messages_stamp_sender_last_active on public.messages;
create trigger messages_stamp_sender_last_active
  after insert on public.messages
  for each row execute function public.stamp_sender_last_active();

-- ============================================================
-- 3. get_daily_matches: add `verified` + `last_active_at`
--    Re-issued verbatim from the live definition with only the two new
--    columns appended to RETURNS TABLE and the final SELECT projection.
--    DROP first: `create or replace` cannot widen a function's RETURNS
--    TABLE signature ("cannot change return type"). No dependent objects
--    exist (verified), and recreating restores the default PUBLIC EXECUTE
--    grant identically, so no explicit re-grant is required.
-- ============================================================
drop function if exists public.get_daily_matches(date);
create or replace function public.get_daily_matches(p_for_date date default current_date)
 returns table(id uuid, pick_user_id uuid, match_reason text, for_date_local date, viewed_at timestamp with time zone, created_at timestamp with time zone, name text, handle text, photo_url text, headline text, bio text, city text, country text, primary_role role_kind, roles role_kind[], goal_type goal_type, verified boolean, last_active_at timestamp with time zone)
 language plpgsql
 security definer
 set search_path to 'public', 'extensions'
as $function$
#variable_conflict use_column
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
    p.goal_type,
    (p.verified_github_username is not null),
    p.last_active_at
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
$function$;

-- ============================================================
-- 4. search_discoverable_profiles: add `verified` + `last_active_at`
--    Re-issued verbatim with only the two new columns appended to
--    RETURNS TABLE and the final SELECT; filters/cursor/limit unchanged.
--    DROP first for the same return-type-widening reason as #3; no
--    dependents, default PUBLIC EXECUTE grant restored on recreate.
-- ============================================================
drop function if exists public.search_discoverable_profiles(text, role_kind[], goal_type[], text, timestamp with time zone, integer);
create or replace function public.search_discoverable_profiles(p_query text default null::text, p_roles role_kind[] default null::role_kind[], p_goal_types goal_type[] default null::goal_type[], p_country text default null::text, p_cursor timestamp with time zone default '9999-12-31 00:00:00+00'::timestamp with time zone, p_limit integer default 20)
 returns table(id uuid, handle text, name text, photo_url text, headline text, bio text, roles role_kind[], primary_role role_kind, city text, country text, goal_type goal_type, goal_text text, created_at timestamp with time zone, verified boolean, last_active_at timestamp with time zone)
 language plpgsql
 stable security definer
 set search_path to 'public', 'extensions'
as $function$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  return query
  select p.id, p.handle::text, p.name, p.photo_url, p.headline, p.bio,
         p.roles, p.primary_role, p.city, p.country, p.goal_type, p.goal_text, p.created_at,
         (p.verified_github_username is not null), p.last_active_at
  from public.profiles p
  where p.onboarded = true and p.id <> v_user
    and not p.private_mode
    and p.created_at < p_cursor
    and not exists (
      select 1 from public.blocks
      where (blocker_id = v_user and blocked_id = p.id)
         or (blocker_id = p.id and blocked_id = v_user)
    )
    and (p_query is null or trim(p_query) = ''
         or p.handle::text ilike '%' || p_query || '%'
         or coalesce(p.name, '') ilike '%' || p_query || '%')
    and (p_roles is null or cardinality(p_roles) = 0
         or exists (select 1 from unnest(p.roles) a join unnest(p_roles) b on a = b))
    and (p_goal_types is null or cardinality(p_goal_types) = 0 or p.goal_type = any(p_goal_types))
    and (p_country is null or trim(p_country) = '' or lower(p.country) = lower(p_country))
  order by p.created_at desc
  limit p_limit;
end;
$function$;

-- ============================================================
-- 5. get_public_profile: hide suspended users
--    Only change is the added `and p.suspended_at is null` filter.
-- ============================================================
create or replace function public.get_public_profile(p_handle text)
 returns table(id uuid, handle text, name text, photo_url text, headline text, bio text, primary_role role_kind, roles role_kind[], city text, country text, verified_github_username text)
 language plpgsql
 stable security definer
 set search_path to 'public', 'extensions'
as $function$
begin
  if p_handle is null or length(trim(p_handle)) = 0 then
    raise exception 'handle required' using errcode='22023';
  end if;
  return query
  select p.id, p.handle::text, p.name, p.photo_url, p.headline, p.bio,
         p.primary_role, p.roles, p.city, p.country,
         case when p.public_investor_page then p.verified_github_username else null end
  from public.profiles p
  where p.handle = trim(p_handle)::extensions.citext
    and p.onboarded = true
    and not p.private_mode
    and p.suspended_at is null;
end;
$function$;

-- ============================================================
-- 6. avatars storage: stop public file LISTing (advisor:
--    public_bucket_allows_listing). Replace the blanket SELECT policy.
--
--    BEFORE  policy "avatars-read"  FOR SELECT TO public
--            USING (bucket_id = 'avatars')
--              -> any caller (incl. anon) can list every object.
--
--    AFTER   policy "avatars-read"  FOR SELECT TO public
--            USING (bucket_id = 'avatars'
--                   and (storage.foldername(name))[1] = auth.uid()::text)
--              -> only the owner can LIST their own files. Public read of an
--                 individual avatar still works because the bucket is public
--                 (objects are served by URL irrespective of RLS).
--    Upload path (avatars-insert / avatars-update) is left untouched.
-- ============================================================
drop policy if exists "avatars-read" on storage.objects;
create policy "avatars-read" on storage.objects for select
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- 7. Pin mutable function search_path (advisor:
--    function_search_path_mutable). Bodies unchanged; config only.
-- ============================================================
alter function public.profiles_set_goal_updated_at() set search_path = public, extensions;
alter function public.bump_conversation_last_message() set search_path = public, extensions;
alter function public.goals_complementary(goal_type, goal_type) set search_path = public, extensions;
