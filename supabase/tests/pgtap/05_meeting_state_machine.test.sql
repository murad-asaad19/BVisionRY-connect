-- pgTAP: meeting state machine (propose / confirm / decline / cancel).
--
-- Under test:
--   * 20260520000000_slice6_meetings.sql — propose_meeting, confirm_meeting,
--     decline_meeting (and the proposer-cannot-self-confirm guard).
--   * 20260606100000_meetings_fixes.sql — cancel_meeting (proposer-only,
--     proposed-only state).

begin;
select plan(8);

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

-- --- fixture ----------------------------------------------------------------
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');

insert into public.conversations (id, participant_a_id, participant_b_id)
values (
  'cccccccc-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222'
);

-- =============================================================================
-- 1. propose_meeting creates a row with state='proposed'.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select lives_ok(
  $$ select public.propose_meeting(
       'cccccccc-3333-3333-3333-333333333333'::uuid,
       array[now() + interval '1 day',
             now() + interval '2 day']::timestamptz[],
       30,
       'https://meet.example.test/abc'
     ) $$,
  'propose_meeting succeeds for a participant'
);

select is(
  (select state::text from public.meeting_proposals
   where conversation_id = 'cccccccc-3333-3333-3333-333333333333'),
  'proposed',
  'propose_meeting initial state is "proposed"'
);

-- =============================================================================
-- 2. confirm_meeting by the OTHER party transitions state to 'confirmed'.
-- =============================================================================
-- Grab the meeting id under service_role for control flow.
reset role;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select lives_ok(
  $$ select public.confirm_meeting(
       (select id from public.meeting_proposals
        where conversation_id = 'cccccccc-3333-3333-3333-333333333333'),
       (select slots[1] from public.meeting_proposals
        where conversation_id = 'cccccccc-3333-3333-3333-333333333333')
     ) $$,
  'confirm_meeting succeeds when called by the non-proposer participant'
);

select is(
  (select state::text from public.meeting_proposals
   where conversation_id = 'cccccccc-3333-3333-3333-333333333333'),
  'confirmed',
  'confirm_meeting transitions state to "confirmed"'
);

-- =============================================================================
-- 3. decline_meeting by the OTHER party on a fresh proposal → 'declined'.
-- =============================================================================
reset role;

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.propose_meeting(
  'cccccccc-3333-3333-3333-333333333333'::uuid,
  array[now() + interval '3 day']::timestamptz[],
  30,
  null
);

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select public.decline_meeting(
  (select id from public.meeting_proposals
   where conversation_id = 'cccccccc-3333-3333-3333-333333333333'
     and state = 'proposed'::public.meeting_state
   order by created_at desc limit 1)
);

select is(
  (select count(*)::int from public.meeting_proposals
   where conversation_id = 'cccccccc-3333-3333-3333-333333333333'
     and state = 'declined'::public.meeting_state),
  1,
  'decline_meeting transitions state to "declined"'
);

-- =============================================================================
-- 4. cancel_meeting by the proposer on a 'proposed' row → 'cancelled'.
-- =============================================================================
reset role;

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.propose_meeting(
  'cccccccc-3333-3333-3333-333333333333'::uuid,
  array[now() + interval '4 day']::timestamptz[],
  30,
  null
);

select public.cancel_meeting(
  (select id from public.meeting_proposals
   where conversation_id = 'cccccccc-3333-3333-3333-333333333333'
     and state = 'proposed'::public.meeting_state
   order by created_at desc limit 1)
);

select is(
  (select count(*)::int from public.meeting_proposals
   where conversation_id = 'cccccccc-3333-3333-3333-333333333333'
     and state = 'cancelled'::public.meeting_state),
  1,
  'cancel_meeting transitions state to "cancelled" when called by proposer on proposed row'
);

-- =============================================================================
-- 5. cancel_meeting rejects a non-proposer caller.
-- =============================================================================
reset role;

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.propose_meeting(
  'cccccccc-3333-3333-3333-333333333333'::uuid,
  array[now() + interval '5 day']::timestamptz[],
  30,
  null
);

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select throws_like(
  $$ select public.cancel_meeting(
       (select id from public.meeting_proposals
        where conversation_id = 'cccccccc-3333-3333-3333-333333333333'
          and state = 'proposed'::public.meeting_state
        order by created_at desc limit 1)
     ) $$,
  '%proposer can cancel%',
  'cancel_meeting raises when caller is not the proposer'
);

-- =============================================================================
-- 6. cancel_meeting rejects a non-proposed state (e.g. already confirmed).
-- =============================================================================
-- Re-use the confirmed proposal from subtest #2; alice (proposer) tries to
-- cancel a confirmed meeting and the function should reject.
reset role;

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select throws_like(
  $$ select public.cancel_meeting(
       (select id from public.meeting_proposals
        where conversation_id = 'cccccccc-3333-3333-3333-333333333333'
          and state = 'confirmed'::public.meeting_state
        order by created_at desc limit 1)
     ) $$,
  '%not in proposed state%',
  'cancel_meeting raises when meeting state is not "proposed"'
);

select * from finish();
rollback;
