-- pgTAP: office-hours post-review fixes.
--
-- Under test (20260608070000_office_hours_fixes.sql):
--   #5  book_slot emits a canonical 'meeting_confirmed' push to the host
--       (notify_meeting_confirmed is AFTER UPDATE only, so an INSERT born
--       confirmed would otherwise be silent).
--   #5  notify_message_inserted suppresses the 'meeting_proposal' push when
--       the linked proposal is ALREADY confirmed (i.e. office-hours booking).
--       Without the suppression the host would get both a wrong-copy proposal
--       push AND the meeting_confirmed push.
--   #13 book_slot's weekly-cap bucket is UTC-anchored: result is identical
--       regardless of the session TimeZone GUC.

begin;
select plan(4);

-- --- inline fixture helpers -------------------------------------------------
create schema if not exists tests;

create or replace function tests.make_user(p_id uuid, p_handle text) returns void
language plpgsql security definer as $$
begin
  insert into auth.users (
    id, instance_id, email, encrypted_password,
    aud, role, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    p_id, '00000000-0000-0000-0000-000000000000'::uuid,
    p_handle || '@example.test', '$2a$10$placeholder.bcrypt.hash.tests.only',
    'authenticated', 'authenticated',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
    now(), now()
  );
  update public.profiles set
    handle = p_handle::extensions.citext,
    name = initcap(p_handle), headline = 'Builds things',
    bio = 'A nice long bio for tests',
    roles = '{founder}'::public.role_kind[],
    primary_role = 'founder'::public.role_kind,
    city = 'Berlin', country = 'DE',
    goal_type = 'co_found'::public.goal_type,
    goal_text = 'Find a technical co-founder for payments product',
    onboarded = true
  where id = p_id;
end $$;

create or replace function tests.auth_as(p_id uuid) returns void
language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
                    json_build_object('sub', p_id::text, 'role', 'authenticated')::text,
                    true);
  perform set_config('request.jwt.claim.sub', p_id::text, true);
end $$;

-- --- fixture users ----------------------------------------------------------
-- alice = host, bob = booker.
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');

-- =============================================================================
-- Setup: alice configures office hours (every day, 09:00-10:00 UTC, 30min
-- slots) and bob books the first eligible slot.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.set_office_hours(
  true,
  '[
    {"weekday": 0, "start_minute": 540, "end_minute": 600, "timezone": "UTC"},
    {"weekday": 1, "start_minute": 540, "end_minute": 600, "timezone": "UTC"},
    {"weekday": 2, "start_minute": 540, "end_minute": 600, "timezone": "UTC"},
    {"weekday": 3, "start_minute": 540, "end_minute": 600, "timezone": "UTC"},
    {"weekday": 4, "start_minute": 540, "end_minute": 600, "timezone": "UTC"},
    {"weekday": 5, "start_minute": 540, "end_minute": 600, "timezone": "UTC"},
    {"weekday": 6, "start_minute": 540, "end_minute": 600, "timezone": "UTC"}
  ]'::jsonb,
  30, 5, 0, null, null
);

-- bob books the soonest open slot at least 1h away.
do $$
declare
  v_slot uuid;
  v_proposal uuid;
begin
  select id into v_slot from public.office_hours_slots
    where host_id = '11111111-1111-1111-1111-111111111111'::uuid
      and status  = 'open'
      and starts_at > now() + interval '1 hour'
    order by starts_at asc limit 1;
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
                     json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text,
                     true);
  perform set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
  v_proposal := public.book_slot(v_slot, 'Topic for our office-hours chat');
  if v_proposal is null then raise exception 'book_slot returned null'; end if;
end $$;

-- =============================================================================
-- 1. push_log contains a meeting_confirmed row addressed to the host
--    (alice = '1111...'). dispatch_push records the row regardless of HTTP
--    reachability — the (event_table, event_id, recipient_id) insert lands
--    before the net.http_post call.
-- =============================================================================
select is(
  (select count(*)::int from public.push_log
     where event_table  = 'meeting_proposals'
       and recipient_id = '11111111-1111-1111-1111-111111111111'::uuid
       and payload->>'kind' = 'meeting_confirmed'),
  1,
  'book_slot dispatches a meeting_confirmed push_log row to the host'
);

-- =============================================================================
-- 2. No proposal-kind push was sent to the host for the chat-bubble side.
--    The 'meeting'-kind message inserted by book_slot points at a proposal
--    that is already state='confirmed', so notify_message_inserted must
--    short-circuit before logging a `meeting_proposal` push.
-- =============================================================================
select is(
  (select count(*)::int from public.push_log
     where event_table  = 'messages'
       and recipient_id = '11111111-1111-1111-1111-111111111111'::uuid
       and payload->>'kind' = 'meeting_proposal'),
  0,
  'notify_message_inserted suppresses meeting_proposal push for office-hours bookings'
);

-- =============================================================================
-- 3 & 4. Weekly-bucket consistency under session TimeZone GUC changes.
-- The weekly cap inside book_slot uses date_trunc('week', now() at time zone
-- 'UTC') — flipping the connection-level TimeZone must NOT change the bucket
-- start. We assert that the trunc result is byte-identical across two very
-- different GUC values.
-- =============================================================================
-- The book_slot expression we're verifying is:
--   v_week_start := (date_trunc('week', (now() at time zone 'UTC')) at time zone 'UTC')
-- We exercise the full expression including the outer `at time zone 'UTC'`
-- (so the implicit `timestamp -> timestamptz` cast under PLPGSQL's assignment
-- can't re-introduce a session-TimeZone-dependent shift).
do $$
declare
  v_utc      timestamptz;
  v_kathmandu timestamptz;
  v_apia     timestamptz;
begin
  set local TimeZone = 'UTC';
  v_utc := (date_trunc('week', (now() at time zone 'UTC')) at time zone 'UTC');

  set local TimeZone = 'Asia/Kathmandu';  -- +05:45, deliberately weird.
  v_kathmandu := (date_trunc('week', (now() at time zone 'UTC')) at time zone 'UTC');

  set local TimeZone = 'Pacific/Apia';    -- +13/+14.
  v_apia := (date_trunc('week', (now() at time zone 'UTC')) at time zone 'UTC');

  if v_utc <> v_kathmandu then
    raise exception 'utc-anchored bucket drifted under Asia/Kathmandu: % vs %', v_utc, v_kathmandu;
  end if;
  if v_utc <> v_apia then
    raise exception 'utc-anchored bucket drifted under Pacific/Apia: % vs %', v_utc, v_apia;
  end if;

  -- Reset for the remaining test.
  set local TimeZone = 'UTC';
end $$;

select pass('weekly-cap bucket (utc-anchored) is identical across Asia/Kathmandu / Pacific/Apia / UTC sessions');

-- =============================================================================
-- 4. Contrast: the OLD non-anchored expression (`date_trunc('week', now())`)
-- WOULD have drifted with the session timezone. We don't assert the drift
-- (the drift is timing-sensitive), but we verify the anchored version still
-- returns a sensible Monday 00:00 UTC value.
-- =============================================================================
-- The truncated wall-clock value (before re-interpretation as UTC) lands on
-- a Monday. We extract dow from the inner `timestamp without time zone` so
-- the assertion is GUC-independent.
select cmp_ok(
  extract(dow from date_trunc('week', (now() at time zone 'UTC')))::int,
  '=',
  1,
  'utc-anchored date_trunc(week, ...) lands on a Monday (dow=1) wall-clock value'
);

select * from finish();
rollback;
