-- Opportunities — post-review fixes (part 1 of 2).
--
-- This migration addresses 4 of 5 review findings against
-- 20260608020000_opportunities.sql. The fifth (trigger redefinition that
-- references a newly-added enum value) ships in the sibling migration
-- 20260608050001_opportunities_fixes_trigger.sql, because Postgres forbids
-- using a newly-added enum value within the same transaction it is added.
--
-- Findings addressed here
-- -----------------------
--   #1  opportunities_open_idx had `expires_at > now()` in its predicate,
--       which Postgres rejects (`functions in index predicate must be
--       marked IMMUTABLE`). The original migration would have aborted at
--       apply time. We drop the index and recreate it status-only;
--       expires_at is already filtered at the application layer (RLS +
--       list_opportunities / get_opportunity RPCs both compare to now()
--       at query time).
--
--   #2  express_interest had no block-check between the viewer and the
--       opportunity author. A user blocked in either direction could
--       still record interest, and the notify trigger then pushed the
--       blocker's identity to the author — a presence leak. We add the
--       bidirectional block-check at the top of the RPC.
--
--   #4  list_opportunities and get_opportunity joined profiles without
--       filtering `onboarded = true`, `private_mode = false`,
--       `suspended_at is null`. Posts by suspended / private / not-yet-
--       onboarded authors stayed publicly discoverable, breaking the
--       project-wide invariant enforced everywhere else in the codebase
--       (see e.g. 20260608010000_second_degree_intros.sql). Both RPCs
--       are SECURITY DEFINER and bypass RLS, so the fix lives inside the
--       function bodies.
--
--   #11 (enum extension only) `opportunity_interest` is added to the
--       notification_kind enum so the existing should_notify(...) helper
--       (and the per-user notification_preferences table) can gate the
--       opportunity-interest push. The actual trigger redefinition that
--       calls should_notify against this new value happens in the
--       sibling migration. No row-add to notification_preferences is
--       required: should_notify() defaults to true when no row exists
--       (see 20260604000000_audit_fixes.sql) — that's the canonical
--       "default-on" convention.

-- =============================================================================
-- Finding #1 — restore IMMUTABLE predicate on opportunities_open_idx.
-- =============================================================================
drop index if exists public.opportunities_open_idx;
create index opportunities_open_idx
  on public.opportunities (created_at desc)
  where status = 'open';

-- =============================================================================
-- Finding #11 (part 1) — extend notification_kind with 'opportunity_interest'.
-- The trigger swap to should_notify(...) lives in the sibling migration so the
-- new enum value is committed before being referenced.
-- =============================================================================
alter type public.notification_kind add value if not exists 'opportunity_interest';

-- =============================================================================
-- Finding #2 — express_interest gains a bidirectional block-check.
-- =============================================================================
create or replace function public.express_interest(
  p_opportunity_id uuid,
  p_note           text default null
) returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user  uuid := auth.uid();
  v_row   public.opportunities;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  select * into v_row from public.opportunities where id = p_opportunity_id;
  if not found then
    raise exception 'opportunity not found' using errcode = 'P0002';
  end if;

  -- A blocked user (in either direction) must not be able to record interest;
  -- otherwise the notify trigger leaks the blocker's identity to the author.
  if exists (
    select 1 from public.blocks b
    where (b.blocker_id = v_user          and b.blocked_id = v_row.author_id)
       or (b.blocker_id = v_row.author_id and b.blocked_id = v_user)
  ) then
    raise exception 'blocked' using errcode = 'P0002';
  end if;

  if v_row.author_id = v_user then
    raise exception 'cannot express interest in your own opportunity' using errcode = '22023';
  end if;
  if v_row.status <> 'open'::public.opportunity_status then
    raise exception 'opportunity is not open' using errcode = '22023';
  end if;
  if v_row.expires_at is not null and v_row.expires_at <= now() then
    raise exception 'opportunity has expired' using errcode = '22023';
  end if;
  if p_note is not null then
    if char_length(btrim(p_note)) < 10 or char_length(p_note) > 500 then
      raise exception 'note must be 10-500 characters' using errcode = '22023';
    end if;
  end if;

  insert into public.opportunity_interests (opportunity_id, user_id, note)
  values (p_opportunity_id, v_user, nullif(btrim(coalesce(p_note, '')), ''))
  on conflict (opportunity_id, user_id) do nothing;
end;
$$;

-- =============================================================================
-- Finding #4 — list_opportunities filters out suspended / private / not-onboarded authors.
-- =============================================================================
create or replace function public.list_opportunities(
  p_kinds        public.opportunity_kind[] default null,
  p_remote_only  boolean                   default false,
  p_search       text                      default null,
  p_limit        int                       default 20,
  p_offset       int                       default 0
)
returns table (
  id                  uuid,
  author_id           uuid,
  kind                public.opportunity_kind,
  title               text,
  body                text,
  tags                text[],
  location_city       text,
  location_country    text,
  remote_ok           boolean,
  expires_at          timestamptz,
  created_at          timestamptz,
  author_handle       text,
  author_name         text,
  author_photo_url    text,
  author_primary_role public.role_kind,
  interested_count    int
)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user   uuid := auth.uid();
  v_limit  int  := least(coalesce(p_limit, 20), 50);
  v_offset int  := greatest(coalesce(p_offset, 0), 0);
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  return query
  select
    o.id,
    o.author_id,
    o.kind,
    o.title,
    o.body,
    o.tags,
    o.location_city,
    o.location_country,
    o.remote_ok,
    o.expires_at,
    o.created_at,
    p.handle::text                                              as author_handle,
    p.name                                                      as author_name,
    p.photo_url                                                 as author_photo_url,
    p.primary_role                                              as author_primary_role,
    (select count(*)::int from public.opportunity_interests oi where oi.opportunity_id = o.id)
                                                                as interested_count
  from public.opportunities o
  join public.profiles p on p.id = o.author_id
  where o.author_id <> v_user
    and o.status = 'open'::public.opportunity_status
    and (o.expires_at is null or o.expires_at > now())
    and (p_kinds is null or o.kind = any(p_kinds))
    and (p_remote_only is not true or o.remote_ok = true)
    and (
      v_search is null
      or o.title ilike '%' || v_search || '%'
      or o.body  ilike '%' || v_search || '%'
    )
    -- Project-wide discovery invariant: hide posts by suspended / private /
    -- not-yet-onboarded authors. Mirrors the filter in
    -- 20260608010000_second_degree_intros.sql.
    and exists (
      select 1 from public.profiles ap
      where ap.id = o.author_id
        and ap.onboarded = true
        and ap.private_mode = false
        and ap.suspended_at is null
    )
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = v_user      and b.blocked_id = o.author_id)
         or (b.blocker_id = o.author_id and b.blocked_id = v_user)
    )
  order by o.created_at desc
  limit v_limit offset v_offset;
end;
$$;

revoke all on function public.list_opportunities(public.opportunity_kind[], boolean, text, int, int) from public, anon;
grant execute on function public.list_opportunities(public.opportunity_kind[], boolean, text, int, int) to authenticated;

-- =============================================================================
-- Finding #4 — get_opportunity filters out suspended / private / not-onboarded authors.
-- Author can still see their own post regardless (own-row escape hatch preserved).
-- =============================================================================
create or replace function public.get_opportunity(p_id uuid)
returns table (
  id                            uuid,
  author_id                     uuid,
  kind                          public.opportunity_kind,
  title                         text,
  body                          text,
  tags                          text[],
  location_city                 text,
  location_country              text,
  remote_ok                     boolean,
  status                        public.opportunity_status,
  expires_at                    timestamptz,
  created_at                    timestamptz,
  closed_at                     timestamptz,
  author_handle                 text,
  author_name                   text,
  author_photo_url              text,
  author_primary_role           public.role_kind,
  interested_count              int,
  viewer_has_expressed_interest boolean
)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  return query
  select
    o.id,
    o.author_id,
    o.kind,
    o.title,
    o.body,
    o.tags,
    o.location_city,
    o.location_country,
    o.remote_ok,
    o.status,
    o.expires_at,
    o.created_at,
    o.closed_at,
    p.handle::text                                                              as author_handle,
    p.name                                                                      as author_name,
    p.photo_url                                                                 as author_photo_url,
    p.primary_role                                                              as author_primary_role,
    (select count(*)::int from public.opportunity_interests oi where oi.opportunity_id = o.id)
                                                                                as interested_count,
    exists (
      select 1 from public.opportunity_interests oi2
      where oi2.opportunity_id = o.id and oi2.user_id = v_user
    )                                                                           as viewer_has_expressed_interest
  from public.opportunities o
  join public.profiles p on p.id = o.author_id
  where o.id = p_id
    and (
      -- Author always sees their own post (any status).
      o.author_id = v_user
      or (
        o.status = 'open'::public.opportunity_status
        and (o.expires_at is null or o.expires_at > now())
        -- Discovery invariant for non-authors: author must be onboarded,
        -- non-private, and not suspended.
        and exists (
          select 1 from public.profiles ap
          where ap.id = o.author_id
            and ap.onboarded = true
            and ap.private_mode = false
            and ap.suspended_at is null
        )
        and not exists (
          select 1 from public.blocks b
          where (b.blocker_id = v_user      and b.blocked_id = o.author_id)
             or (b.blocker_id = o.author_id and b.blocked_id = v_user)
        )
      )
    );
end;
$$;

revoke all on function public.get_opportunity(uuid) from public, anon;
grant execute on function public.get_opportunity(uuid) to authenticated;
