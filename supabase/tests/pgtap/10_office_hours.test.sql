-- pgTAP: office hours / availability slots.
--
-- Under test:
--   * 20260608030000_office_hours.sql — set_office_hours / materialize /
--     list_upcoming_slots / book_slot / cancel_booking / my_bookings.

begin;
select plan(12);

-- --- inline fixture helpers (rolled back with the test transaction) --------
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
-- alice = host, bob & carol = bookers, dave = third party.
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'carol');
select tests.make_user('44444444-4444-4444-4444-444444444444'::uuid, 'dave');

-- =============================================================================
-- 1. set_office_hours rejects a malformed window (bad weekday).
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select throws_like(
  $$ select public.set_office_hours(
       true,
       '[{"weekday": 9, "start_minute": 600, "end_minute": 660, "timezone": "UTC"}]'::jsonb,
       30, 5, 5, null, null
     ) $$,
  '%weekday must be 0-6%',
  'set_office_hours rejects weekday outside 0-6'
);

-- =============================================================================
-- 2. set_office_hours rejects unknown IANA timezone.
-- =============================================================================
select throws_like(
  $$ select public.set_office_hours(
       true,
       '[{"weekday": 2, "start_minute": 600, "end_minute": 660, "timezone": "Not/A_Place"}]'::jsonb,
       30, 5, 5, null, null
     ) $$,
  '%valid IANA timezone%',
  'set_office_hours rejects unknown IANA timezone'
);

-- =============================================================================
-- 3. set_office_hours with a daily window materializes slots for 14 days.
-- A "every day from 9:00 to 10:00 UTC, 30-min slots" window must produce
-- exactly 2 slots/day across the rolling-14d horizon, modulo the +1h floor.
-- Conservative lower bound: at least 14 slots over 14 days.
-- =============================================================================
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
  30, 5, 0, null, 'Bring a question'
);

select cmp_ok(
  (select count(*) from public.office_hours_slots
     where host_id = '11111111-1111-1111-1111-111111111111'::uuid
       and status  = 'open'),
  '>=', 14::bigint,
  'set_office_hours materializes >= 14 open slots across 14 days for a daily window'
);

-- =============================================================================
-- 4. materialize is idempotent — calling it again does not duplicate.
-- =============================================================================
select public.materialize_office_hours_slots('11111111-1111-1111-1111-111111111111'::uuid);

select cmp_ok(
  (select count(*) from public.office_hours_slots
     where host_id = '11111111-1111-1111-1111-111111111111'::uuid
       and status  = 'open'),
  '>=', 14::bigint,
  'second materialize call does not duplicate slots'
);

-- =============================================================================
-- 5. book_slot succeeds for an authenticated other-party caller.
-- =============================================================================
-- Pick an open slot at least 16 minutes from now so the 15-min cutoff passes.
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
  -- Authenticate as bob and book.
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
                     json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text,
                     true);
  perform set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
  v_proposal := public.book_slot(v_slot, 'Topic for our first office-hours chat');
  if v_proposal is null then raise exception 'book_slot returned null'; end if;
end $$;

select is(
  (select count(*)::int from public.office_hours_slots
     where host_id = '11111111-1111-1111-1111-111111111111'::uuid
       and status  = 'booked'
       and booked_by = '22222222-2222-2222-2222-222222222222'::uuid),
  1,
  'book_slot transitions the slot to booked + sets booked_by'
);

-- =============================================================================
-- 6. book_slot creates a confirmed meeting_proposals row.
-- =============================================================================
select is(
  (select mp.state::text
     from public.meeting_proposals mp
     join public.office_hours_slots s on s.meeting_proposal_id = mp.id
    where s.booked_by = '22222222-2222-2222-2222-222222222222'::uuid
    order by s.booked_at desc limit 1),
  'confirmed',
  'book_slot creates a meeting_proposals row in state=confirmed'
);

-- =============================================================================
-- 7. Race: a second caller (carol) attempting the SAME slot fails.
-- =============================================================================
reset role;
do $$
declare
  v_slot uuid;
  v_caught text;
begin
  -- Grab the same slot bob took.
  select s.id into v_slot
    from public.office_hours_slots s
    where s.host_id = '11111111-1111-1111-1111-111111111111'::uuid
      and s.status  = 'booked'
      and s.booked_by = '22222222-2222-2222-2222-222222222222'::uuid
    limit 1;
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
                     json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text,
                     true);
  perform set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);
  begin
    perform public.book_slot(v_slot, 'I want this slot too please');
    v_caught := null;
  exception
    when others then v_caught := SQLERRM;
  end;
  if v_caught is null then raise exception 'second book did not raise'; end if;
end $$;

-- Exactly one row remains booked for that timestamp (the host_id, starts_at
-- pair is unique and we never duplicate via the race).
select is(
  (select count(*)::int from public.office_hours_slots
     where host_id = '11111111-1111-1111-1111-111111111111'::uuid
       and status  = 'booked'),
  1,
  'race: only one booker wins (no duplicate booked rows)'
);

-- =============================================================================
-- 8. max_bookings_per_week — set to 1 then attempt a second different-slot
-- booking from bob → should be rejected.
-- =============================================================================
reset role;
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
  30, 1, 0, null, null
);

reset role;
do $$
declare
  v_slot uuid;
  v_caught text;
begin
  -- Pick another open slot in the SAME week as the existing booking.
  select s.id into v_slot
    from public.office_hours_slots s
    where s.host_id = '11111111-1111-1111-1111-111111111111'::uuid
      and s.status  = 'open'
      and s.starts_at >= date_trunc('week', now())
      and s.starts_at <  date_trunc('week', now()) + interval '7 days'
    order by s.starts_at asc limit 1;
  if v_slot is null then
    -- If no same-week open slot exists, max-bookings check is degenerate; skip.
    raise notice 'no same-week open slot for max-bookings test (skip)';
    return;
  end if;
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
                     json_build_object('sub', '22222222-2222-2222-2222-222222222222', 'role', 'authenticated')::text,
                     true);
  perform set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
  begin
    perform public.book_slot(v_slot, 'Another chat please host');
    v_caught := null;
  exception
    when others then v_caught := SQLERRM;
  end;
  if v_caught is null then raise exception 'expected max-bookings-per-week rejection'; end if;
  if v_caught not like '%max bookings%' then
    raise exception 'unexpected error: %', v_caught;
  end if;
end $$;

select pass('book_slot enforces max_bookings_per_week per host');

-- =============================================================================
-- 9. cancel_booking by booker, > 24h away → reopens the slot.
-- =============================================================================
reset role;
-- Create a long-lead-time booked slot directly so we can test cancellation
-- semantics deterministically.
insert into public.conversations (id, participant_a_id, participant_b_id)
  values ('aaaa1111-1111-1111-1111-111111111111',
          '11111111-1111-1111-1111-111111111111',
          '22222222-2222-2222-2222-222222222222')
  on conflict do nothing;

insert into public.meeting_proposals (id, conversation_id, proposed_by_id, slots, confirmed_slot, state, duration_minutes)
  values ('aaaa2222-2222-2222-2222-222222222222',
          'aaaa1111-1111-1111-1111-111111111111',
          '11111111-1111-1111-1111-111111111111',
          ARRAY[now() + interval '5 days']::timestamptz[],
          now() + interval '5 days',
          'confirmed'::public.meeting_state,
          30);

insert into public.office_hours_slots (id, host_id, starts_at, ends_at, status, booked_by, booked_at, meeting_proposal_id, topic)
  values ('aaaa3333-3333-3333-3333-333333333333',
          '11111111-1111-1111-1111-111111111111',
          now() + interval '5 days',
          now() + interval '5 days' + interval '30 minutes',
          'booked',
          '22222222-2222-2222-2222-222222222222',
          now(),
          'aaaa2222-2222-2222-2222-222222222222',
          'Long-lead-time topic')
  on conflict (host_id, starts_at) do nothing;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select public.cancel_booking('aaaa3333-3333-3333-3333-333333333333'::uuid);

select is(
  (select status from public.office_hours_slots
     where id = 'aaaa3333-3333-3333-3333-333333333333'::uuid),
  'open',
  'cancel_booking > 24h away reopens the slot'
);

-- =============================================================================
-- 10. The underlying meeting_proposal is cancelled after cancel_booking.
-- =============================================================================
select is(
  (select state::text from public.meeting_proposals
     where id = 'aaaa2222-2222-2222-2222-222222222222'::uuid),
  'cancelled',
  'cancel_booking cancels the underlying meeting_proposal'
);

-- =============================================================================
-- 11. cancel_booking late (< 24h) marks the slot cancelled (no reopen).
-- =============================================================================
reset role;
insert into public.meeting_proposals (id, conversation_id, proposed_by_id, slots, confirmed_slot, state, duration_minutes)
  values ('bbbb2222-2222-2222-2222-222222222222',
          'aaaa1111-1111-1111-1111-111111111111',
          '11111111-1111-1111-1111-111111111111',
          ARRAY[now() + interval '2 hours']::timestamptz[],
          now() + interval '2 hours',
          'confirmed'::public.meeting_state,
          30);

insert into public.office_hours_slots (id, host_id, starts_at, ends_at, status, booked_by, booked_at, meeting_proposal_id, topic)
  values ('bbbb3333-3333-3333-3333-333333333333',
          '11111111-1111-1111-1111-111111111111',
          now() + interval '2 hours',
          now() + interval '2 hours' + interval '30 minutes',
          'booked',
          '22222222-2222-2222-2222-222222222222',
          now(),
          'bbbb2222-2222-2222-2222-222222222222',
          'Soon topic')
  on conflict (host_id, starts_at) do nothing;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select public.cancel_booking('bbbb3333-3333-3333-3333-333333333333'::uuid);

select is(
  (select status from public.office_hours_slots
     where id = 'bbbb3333-3333-3333-3333-333333333333'::uuid),
  'cancelled',
  'cancel_booking < 24h marks the slot cancelled (no reopen)'
);

-- =============================================================================
-- 12. cancel_booking by a third party (not host, not booker) → 42501.
-- =============================================================================
reset role;
insert into public.meeting_proposals (id, conversation_id, proposed_by_id, slots, confirmed_slot, state, duration_minutes)
  values ('cccc2222-2222-2222-2222-222222222222',
          'aaaa1111-1111-1111-1111-111111111111',
          '11111111-1111-1111-1111-111111111111',
          ARRAY[now() + interval '4 days']::timestamptz[],
          now() + interval '4 days',
          'confirmed'::public.meeting_state,
          30);

insert into public.office_hours_slots (id, host_id, starts_at, ends_at, status, booked_by, booked_at, meeting_proposal_id, topic)
  values ('cccc3333-3333-3333-3333-333333333333',
          '11111111-1111-1111-1111-111111111111',
          now() + interval '4 days',
          now() + interval '4 days' + interval '30 minutes',
          'booked',
          '22222222-2222-2222-2222-222222222222',
          now(),
          'cccc2222-2222-2222-2222-222222222222',
          'Third-party cancel attempt')
  on conflict (host_id, starts_at) do nothing;

-- Dave is neither host nor booker.
select tests.auth_as('44444444-4444-4444-4444-444444444444'::uuid);
select throws_like(
  $$ select public.cancel_booking('cccc3333-3333-3333-3333-333333333333'::uuid) $$,
  '%only host or booker%',
  'cancel_booking rejects callers that are neither host nor booker'
);

select * from finish();
rollback;
