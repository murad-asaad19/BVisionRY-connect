-- pgTAP: get_profile_signals — mutual-connection count + meeting-review average.
--
-- Under test:
--   * 20260608000000_profile_signals.sql — get_profile_signals(p_target).
--
-- Schema note: meeting_reviews stores outcome ('useful' | 'not_useful' |
-- 'no_show') as of 20260604000000_audit_fixes.sql, not the int rating
-- the original RPC plan referenced. get_profile_signals maps
--     useful → 5, not_useful → 2, no_show → 1
-- and averages those mapped values. The test fixtures use 'useful' to
-- get a clean 5.0 average for the ≥3-review case.

begin;
select plan(11);

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

-- NB: NOT security definer — see note in 01_intro_lifecycle.test.sql.
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
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'carol');
select tests.make_user('44444444-4444-4444-4444-444444444444'::uuid, 'dave');
select tests.make_user('55555555-5555-5555-5555-555555555555'::uuid, 'eve');

-- =============================================================================
-- 1. Empty case — alice viewing bob with no intros and no reviews → zeros.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select mutual_connection_count
     from public.get_profile_signals('22222222-2222-2222-2222-222222222222'::uuid)),
  0,
  'empty case: mutual_connection_count is 0'
);

select is(
  (select total_meeting_reviews
     from public.get_profile_signals('22222222-2222-2222-2222-222222222222'::uuid)),
  0,
  'empty case: total_meeting_reviews is 0'
);

select is(
  (select avg_meeting_rating
     from public.get_profile_signals('22222222-2222-2222-2222-222222222222'::uuid)),
  null,
  'empty case: avg_meeting_rating is null'
);

-- =============================================================================
-- 2. Mutual count: alice & bob both connected to carol → mutual = 1.
-- =============================================================================
-- Reset role so the inserts aren't RLS-filtered for the test fixture.
reset role;

-- alice ↔ carol connected
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values (
  '11111111-1111-1111-1111-111111111111',
  '33333333-3333-3333-3333-333333333333',
  rpad('alice→carol connected intro note ', 100, 'x'),
  'connected'::public.intro_state,
  now()
);

-- bob ↔ carol connected
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values (
  '33333333-3333-3333-3333-333333333333',
  '22222222-2222-2222-2222-222222222222',
  rpad('carol→bob connected intro note ', 100, 'x'),
  'connected'::public.intro_state,
  now()
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select mutual_connection_count
     from public.get_profile_signals('22222222-2222-2222-2222-222222222222'::uuid)),
  1,
  'alice viewing bob: 1 mutual connection (carol)'
);

-- Symmetric: bob viewing alice should also see 1.
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select is(
  (select mutual_connection_count
     from public.get_profile_signals('11111111-1111-1111-1111-111111111111'::uuid)),
  1,
  'bob viewing alice: 1 mutual connection (symmetric derivation)'
);

-- =============================================================================
-- 3. Reviewee with 2 reviews → avg_meeting_rating null, total = 2.
-- =============================================================================
reset role;

-- Conversation between bob and dave so dave can be reviewed by bob.
insert into public.conversations (id, participant_a_id, participant_b_id)
values (
  'cccccccc-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '44444444-4444-4444-4444-444444444444'
);

-- Two meetings between bob and dave, both confirmed.
insert into public.meeting_proposals (id, conversation_id, proposer_id, slots, duration_minutes, state, confirmed_slot)
values
  ('a1111111-1111-1111-1111-111111111111',
   'cccccccc-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222',
   array[now() - interval '2 day']::timestamptz[], 30,
   'confirmed'::public.meeting_state, now() - interval '2 day'),
  ('a2222222-2222-2222-2222-222222222222',
   'cccccccc-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222',
   array[now() - interval '3 day']::timestamptz[], 30,
   'confirmed'::public.meeting_state, now() - interval '3 day');

-- Bob reviews dave twice (one per meeting).
insert into public.meeting_reviews (meeting_id, reviewer_id, outcome)
values
  ('a1111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'useful'),
  ('a2222222-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222', 'useful');

-- alice viewing dave should see total=2 and avg=null (below threshold).
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select total_meeting_reviews
     from public.get_profile_signals('44444444-4444-4444-4444-444444444444'::uuid)),
  2,
  'dave with 2 reviews: total_meeting_reviews = 2'
);

select is(
  (select avg_meeting_rating
     from public.get_profile_signals('44444444-4444-4444-4444-444444444444'::uuid)),
  null,
  'dave with 2 reviews: avg_meeting_rating hidden (null) — under ≥3 threshold'
);

-- =============================================================================
-- 4. Reviewee with 3 reviews ('useful' × 3 → mapped 5s) → avg = 5.0, total = 3.
-- =============================================================================
reset role;

-- Conversations + meetings between dave and three different reviewers so
-- (meeting_id, reviewer_id) is unique. Use carol, alice, and eve.
insert into public.conversations (id, participant_a_id, participant_b_id)
values
  ('cccccccc-2222-2222-2222-222222222222',
   '33333333-3333-3333-3333-333333333333',
   '44444444-4444-4444-4444-444444444444'),
  ('cccccccc-3333-3333-3333-333333333333',
   '11111111-1111-1111-1111-111111111111',
   '44444444-4444-4444-4444-444444444444'),
  ('cccccccc-4444-4444-4444-444444444444',
   '55555555-5555-5555-5555-555555555555',
   '44444444-4444-4444-4444-444444444444');

insert into public.meeting_proposals (id, conversation_id, proposer_id, slots, duration_minutes, state, confirmed_slot)
values
  ('a3333333-3333-3333-3333-333333333333',
   'cccccccc-2222-2222-2222-222222222222',
   '44444444-4444-4444-4444-444444444444',
   array[now() - interval '4 day']::timestamptz[], 30,
   'confirmed'::public.meeting_state, now() - interval '4 day'),
  ('a4444444-4444-4444-4444-444444444444',
   'cccccccc-3333-3333-3333-333333333333',
   '44444444-4444-4444-4444-444444444444',
   array[now() - interval '5 day']::timestamptz[], 30,
   'confirmed'::public.meeting_state, now() - interval '5 day'),
  ('a5555555-5555-5555-5555-555555555555',
   'cccccccc-4444-4444-4444-444444444444',
   '44444444-4444-4444-4444-444444444444',
   array[now() - interval '6 day']::timestamptz[], 30,
   'confirmed'::public.meeting_state, now() - interval '6 day');

insert into public.meeting_reviews (meeting_id, reviewer_id, outcome)
values
  ('a3333333-3333-3333-3333-333333333333',
   '33333333-3333-3333-3333-333333333333', 'useful'),
  ('a4444444-4444-4444-4444-444444444444',
   '11111111-1111-1111-1111-111111111111', 'useful'),
  ('a5555555-5555-5555-5555-555555555555',
   '55555555-5555-5555-5555-555555555555', 'useful');

-- alice viewing dave: total reviews = 2 (bob×2) + 3 (new) = 5, avg = 5.0.
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select total_meeting_reviews
     from public.get_profile_signals('44444444-4444-4444-4444-444444444444'::uuid)),
  5,
  'dave with 5 reviews: total_meeting_reviews = 5'
);

select is(
  (select avg_meeting_rating
     from public.get_profile_signals('44444444-4444-4444-4444-444444444444'::uuid)),
  5.0::numeric(2,1),
  'dave with 5 ''useful'' reviews → avg_meeting_rating = 5.0 (above ≥3 threshold)'
);

-- =============================================================================
-- 5. Block in either direction → signals zeroed out (no leak).
-- =============================================================================
reset role;
insert into public.blocks (blocker_id, blocked_id)
values (
  '11111111-1111-1111-1111-111111111111',
  '44444444-4444-4444-4444-444444444444'
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select total_meeting_reviews
     from public.get_profile_signals('44444444-4444-4444-4444-444444444444'::uuid)),
  0,
  'alice blocked dave: total_meeting_reviews returned as 0 (no leak)'
);

-- =============================================================================
-- 6. Self-view → zeros / nulls.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select mutual_connection_count
     from public.get_profile_signals('11111111-1111-1111-1111-111111111111'::uuid)),
  0,
  'self-view: mutual_connection_count is 0'
);

select * from finish();
rollback;
