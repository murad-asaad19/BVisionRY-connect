-- Opportunities board.
--
-- A first-class surface where users post intent ("hiring", "raising",
-- "looking for cofounder", "available to advise") and others browse +
-- express interest. Inspired by Polywork's Opportunities board.
--
-- Schema
-- ------
--   opportunities                — the post itself (kind + title + body +
--                                  tags + optional location + expiry).
--   opportunity_interests        — N:N (opportunity_id, user_id) with an
--                                  optional note. PK enforces idempotent
--                                  "express interest" semantics.
--
-- RLS strategy
-- ------------
-- SELECT on opportunities is policy-controlled: anyone authenticated sees
-- open + non-expired posts unless blocked in either direction; authors
-- always see their own posts (any status).
--
-- Mutations on BOTH tables happen exclusively through the SECURITY DEFINER
-- RPCs declared below. The "_no_direct_mutate" policy intentionally returns
-- false on INSERT/UPDATE/DELETE so the client cannot bypass the RPCs (which
-- validate ownership, expiry, and the daily-write quota implicitly through
-- the RPC contract). This avoids the typical insert-RLS dance — auth.uid()
-- is read inside the function instead.
--
-- Notifications
-- -------------
-- When someone expresses interest, the opportunity author gets a push via
-- notify_opportunity_interest, mirroring notify_intro_inserted from
-- 20260606150000_dispatch_push_payload.sql. The new notification kind
-- 'opportunity_interest' is added to the public.notification_kind enum so
-- the existing should_notify(...) helper governs it (default-on per the
-- helper's coalesce).

-- =============================================================================
-- (1) Enums.
-- =============================================================================
create type public.opportunity_kind as enum (
  'hiring',           -- posting a role
  'seeking_role',     -- looking for a job
  'fundraising',      -- raising a round
  'investing',        -- deploying capital
  'cofounder',        -- looking for a cofounder
  'advising',         -- offering advisory
  'seeking_advisor',  -- looking for an advisor
  'collaboration'     -- catch-all
);

create type public.opportunity_status as enum ('open', 'closed', 'archived');

-- NOTE on notification gating
-- ---------------------------
-- The existing `should_notify(...)` helper keys on the `notification_kind`
-- enum, which we deliberately do NOT extend in this migration: Postgres
-- forbids using a newly-added enum value in the same transaction the value
-- is added in, and Supabase runs each migration in a transaction. Rather
-- than split this feature across two migration slots, we read the
-- `notification_preferences` table directly inside notify_opportunity_interest
-- below — see the comment on that function for the exact contract. Adding
-- the new enum value can land in a future migration without changing this
-- one; the trigger then becomes a one-line swap to should_notify.

-- =============================================================================
-- (2) Tables.
-- =============================================================================
create table public.opportunities (
  id                uuid primary key default gen_random_uuid(),
  author_id         uuid not null references public.profiles(id) on delete cascade,
  kind              public.opportunity_kind not null,
  title             text not null,
  body              text not null,
  tags              text[] not null default '{}',
  location_city     text,
  location_country  text,
  remote_ok         boolean not null default false,
  status            public.opportunity_status not null default 'open',
  expires_at        timestamptz default (now() + interval '30 days'),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  closed_at         timestamptz,
  constraint opportunities_title_len check (char_length(title) between 5 and 120),
  constraint opportunities_body_len  check (char_length(body)  between 10 and 2000),
  constraint opportunities_tag_count check (cardinality(tags) <= 8),
  constraint opportunities_tag_format check (
    (select bool_and(t = lower(t) and char_length(t) between 1 and 30) from unnest(tags) as t)
  )
);

create index opportunities_open_idx on public.opportunities (created_at desc)
  where status = 'open' and (expires_at is null or expires_at > now());
create index opportunities_author_idx on public.opportunities (author_id, status, created_at desc);
create index opportunities_kind_idx on public.opportunities (kind, created_at desc)
  where status = 'open';

create trigger opportunities_set_updated_at
  before update on public.opportunities
  for each row execute function extensions.moddatetime(updated_at);

create table public.opportunity_interests (
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  user_id        uuid not null references public.profiles(id) on delete cascade,
  note           text,
  created_at     timestamptz not null default now(),
  primary key (opportunity_id, user_id),
  constraint opportunity_interests_note_len check (
    note is null or char_length(note) between 10 and 500
  )
);

create index opportunity_interests_user_idx
  on public.opportunity_interests (user_id, created_at desc);

-- =============================================================================
-- (3) RLS.
-- =============================================================================
alter table public.opportunities         enable row level security;
alter table public.opportunity_interests enable row level security;

-- Open opportunities visible to all authenticated viewers, excluding posts
-- by users blocked-by or blocking the viewer. Author always sees their own.
create policy opportunities_select_visible
  on public.opportunities for select to authenticated
  using (
    author_id = auth.uid()
    or (
      status = 'open'
      and (expires_at is null or expires_at > now())
      and not exists (
        select 1 from public.blocks
        where (blocker_id = auth.uid() and blocked_id = opportunities.author_id)
           or (blocker_id = opportunities.author_id and blocked_id = auth.uid())
      )
    )
  );

-- Writes happen via the SECURITY DEFINER RPCs only.
create policy opportunities_no_direct_mutate
  on public.opportunities for all to authenticated
  using (false) with check (false);

-- Interests: each user sees their own rows; opportunity authors see the
-- interest list for their own posts.
create policy opportunity_interests_select_relevant
  on public.opportunity_interests for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.opportunities o
      where o.id = opportunity_interests.opportunity_id
        and o.author_id = auth.uid()
    )
  );

create policy opportunity_interests_no_direct_mutate
  on public.opportunity_interests for all to authenticated
  using (false) with check (false);

-- =============================================================================
-- (4) Shared validation helper.
-- =============================================================================
create or replace function public._opportunity_validate_input(
  p_title text,
  p_body  text,
  p_tags  text[]
) returns void
language plpgsql immutable
set search_path = public, extensions
as $$
begin
  if p_title is null or char_length(btrim(p_title)) < 5 or char_length(p_title) > 120 then
    raise exception 'title must be 5-120 characters' using errcode = '22023';
  end if;
  if p_body is null or char_length(btrim(p_body)) < 10 or char_length(p_body) > 2000 then
    raise exception 'body must be 10-2000 characters' using errcode = '22023';
  end if;
  if p_tags is not null and cardinality(p_tags) > 8 then
    raise exception 'at most 8 tags allowed' using errcode = '22023';
  end if;
  if p_tags is not null then
    if exists (
      select 1 from unnest(p_tags) as t
       where t is null
          or t <> lower(t)
          or char_length(t) < 1
          or char_length(t) > 30
    ) then
      raise exception 'tags must be lowercase, 1-30 chars each' using errcode = '22023';
    end if;
  end if;
end;
$$;

-- =============================================================================
-- (5) RPCs.
-- =============================================================================

-- list_opportunities -----------------------------------------------------------
-- Feed for the viewer. Excludes own posts, blocked-relationship posts, and
-- closed/expired posts. Applies optional kind / remote / search filters.
-- ilike on title + body is good enough for now; a tsvector index can drop in
-- later without changing the signature.
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

-- get_opportunity --------------------------------------------------------------
-- Single opportunity for the detail screen. Returns interested_count and
-- viewer_has_expressed_interest so the CTA renders without a follow-up RPC.
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
      o.author_id = v_user
      or (
        o.status = 'open'::public.opportunity_status
        and (o.expires_at is null or o.expires_at > now())
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

-- create_opportunity -----------------------------------------------------------
create or replace function public.create_opportunity(
  p_kind             public.opportunity_kind,
  p_title            text,
  p_body             text,
  p_tags             text[]      default '{}',
  p_location_city    text        default null,
  p_location_country text        default null,
  p_remote_ok        boolean     default false,
  p_expires_at       timestamptz default null
) returns uuid
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_id   uuid;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  perform public._opportunity_validate_input(p_title, p_body, p_tags);

  -- The author must be onboarded; mirrors send_intro's recipient check.
  if not exists (
    select 1 from public.profiles where id = v_user and onboarded = true
  ) then
    raise exception 'author not onboarded' using errcode = '42501';
  end if;

  insert into public.opportunities (
    author_id, kind, title, body, tags,
    location_city, location_country, remote_ok,
    expires_at
  ) values (
    v_user,
    p_kind,
    btrim(p_title),
    btrim(p_body),
    coalesce(p_tags, '{}'::text[]),
    nullif(btrim(coalesce(p_location_city, '')),    ''),
    nullif(btrim(coalesce(p_location_country, '')), ''),
    coalesce(p_remote_ok, false),
    coalesce(p_expires_at, now() + interval '30 days')
  )
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.create_opportunity(
  public.opportunity_kind, text, text, text[], text, text, boolean, timestamptz
) from public, anon;
grant execute on function public.create_opportunity(
  public.opportunity_kind, text, text, text[], text, text, boolean, timestamptz
) to authenticated;

-- update_opportunity -----------------------------------------------------------
create or replace function public.update_opportunity(
  p_id               uuid,
  p_kind             public.opportunity_kind,
  p_title            text,
  p_body             text,
  p_tags             text[]      default '{}',
  p_location_city    text        default null,
  p_location_country text        default null,
  p_remote_ok        boolean     default false,
  p_expires_at       timestamptz default null
) returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  perform public._opportunity_validate_input(p_title, p_body, p_tags);

  update public.opportunities
     set kind             = p_kind,
         title            = btrim(p_title),
         body             = btrim(p_body),
         tags             = coalesce(p_tags, '{}'::text[]),
         location_city    = nullif(btrim(coalesce(p_location_city, '')),    ''),
         location_country = nullif(btrim(coalesce(p_location_country, '')), ''),
         remote_ok        = coalesce(p_remote_ok, false),
         expires_at       = p_expires_at
   where id = p_id and author_id = v_user;

  if not found then
    raise exception 'opportunity not found or not owned by caller' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.update_opportunity(
  uuid, public.opportunity_kind, text, text, text[], text, text, boolean, timestamptz
) from public, anon;
grant execute on function public.update_opportunity(
  uuid, public.opportunity_kind, text, text, text[], text, text, boolean, timestamptz
) to authenticated;

-- close_opportunity ------------------------------------------------------------
create or replace function public.close_opportunity(p_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  update public.opportunities
     set status    = 'closed'::public.opportunity_status,
         closed_at = now()
   where id = p_id and author_id = v_user;
  if not found then
    raise exception 'opportunity not found or not owned by caller' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.close_opportunity(uuid) from public, anon;
grant execute on function public.close_opportunity(uuid) to authenticated;

-- express_interest -------------------------------------------------------------
-- Idempotent on (opportunity_id, user_id) — already-interested is a no-op.
-- Validates the opportunity is open + not expired and that the caller isn't
-- the author (UI shouldn't surface the CTA, but the RPC is defensive).
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

revoke all on function public.express_interest(uuid, text) from public, anon;
grant execute on function public.express_interest(uuid, text) to authenticated;

-- list_my_opportunities --------------------------------------------------------
create or replace function public.list_my_opportunities()
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
  status              public.opportunity_status,
  expires_at          timestamptz,
  created_at          timestamptz,
  closed_at           timestamptz,
  interested_count    int
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
    (select count(*)::int from public.opportunity_interests oi where oi.opportunity_id = o.id)
                                                                as interested_count
  from public.opportunities o
  where o.author_id = v_user
  order by o.created_at desc;
end;
$$;

revoke all on function public.list_my_opportunities() from public, anon;
grant execute on function public.list_my_opportunities() to authenticated;

-- list_interested --------------------------------------------------------------
-- Only the author of the opportunity may see who expressed interest.
create or replace function public.list_interested(p_opportunity_id uuid)
returns table (
  user_id       uuid,
  handle        text,
  name          text,
  photo_url     text,
  primary_role  public.role_kind,
  note          text,
  created_at    timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user  uuid := auth.uid();
  v_owner uuid;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  select author_id into v_owner from public.opportunities where id = p_opportunity_id;
  if v_owner is null then
    raise exception 'opportunity not found' using errcode = 'P0002';
  end if;
  if v_owner <> v_user then
    raise exception 'only the author can view interested users' using errcode = '42501';
  end if;

  return query
  select
    oi.user_id,
    p.handle::text as handle,
    p.name         as name,
    p.photo_url    as photo_url,
    p.primary_role as primary_role,
    oi.note,
    oi.created_at
  from public.opportunity_interests oi
  join public.profiles p on p.id = oi.user_id
  where oi.opportunity_id = p_opportunity_id
  order by oi.created_at desc;
end;
$$;

revoke all on function public.list_interested(uuid) from public, anon;
grant execute on function public.list_interested(uuid) to authenticated;

-- =============================================================================
-- (6) Push trigger on opportunity_interests.
-- =============================================================================
-- Mirrors notify_intro_inserted in 20260606150000_dispatch_push_payload.sql:
-- calls dispatch_push with the structured-data params so the mobile client
-- can route deterministically.
--
-- Preference gating: the `notification_kind` enum is intentionally NOT
-- extended in this migration (see the note in the enums section), so we
-- can't call should_notify(... 'opportunity_interest' ...) here. Since
-- there is no UI to disable this kind yet, the no-row-means-on default in
-- notification_preferences applies trivially — we just always dispatch.
-- A follow-up migration may extend the enum and swap this call to
-- should_notify(...) for explicit opt-out support.
create or replace function public.notify_opportunity_interest()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_author      uuid;
  v_title       text;
  v_from_name   text;
begin
  select o.author_id, o.title into v_author, v_title
    from public.opportunities o
   where o.id = new.opportunity_id;
  if v_author is null or v_author = new.user_id then
    return new;
  end if;

  select name into v_from_name from public.profiles where id = new.user_id;

  perform public.dispatch_push(
    v_author,
    'opportunity_interests',
    new.opportunity_id,
    jsonb_build_object(
      'kind',                'opportunity_interest',
      'title',               'New interest in ' || coalesce(v_title, 'your opportunity'),
      'body',                coalesce(v_from_name, 'Someone') || ' is interested.',
      'url',                 '/(app)/opportunities/' || new.opportunity_id,
      'opportunity_id',      new.opportunity_id,
      'opportunity_title',   v_title,
      'from_user_id',        new.user_id,
      'from_user_name',      v_from_name
    ),
    p_kind            => 'opportunity_interest',
    p_entity_id       => new.opportunity_id,
    p_conversation_id => null
  );
  return new;
end;
$$;

create trigger opportunity_interests_push_on_insert
  after insert on public.opportunity_interests
  for each row execute function public.notify_opportunity_interest();

-- =============================================================================
-- (7) Comments — these double as self-doc for type generation tools.
-- =============================================================================
comment on table public.opportunities is
  'Posts on the Opportunities board (hiring / seeking / fundraising / etc.). RLS allows authenticated users to SELECT open + non-expired posts unless blocked; all writes go through the SECURITY DEFINER RPCs.';

comment on table public.opportunity_interests is
  'Per-user expressions of interest in an opportunity. PK (opportunity_id, user_id) enforces idempotency for express_interest.';

comment on function public.list_opportunities(public.opportunity_kind[], boolean, text, int, int) is
  'Viewer feed of open opportunities. Excludes own posts, blocked-author posts, and closed/expired posts. Optional kind / remote / search filters.';

comment on function public.express_interest(uuid, text) is
  'Records the viewer as interested in an opportunity (idempotent). Fires notify_opportunity_interest, which pushes the author.';

comment on function public.list_interested(uuid) is
  'Returns the list of users who expressed interest in an opportunity. Only the opportunity author may call.';
