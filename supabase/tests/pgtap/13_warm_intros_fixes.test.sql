-- pgTAP: warm-intro hardening fixes.
--
-- Under test:
--   * 20260608060000_warm_intros_fixes.sql
--     - accept_intro refuses warm_request kind.
--     - decline_intro on warm_request transitions state without stamping declined_at.
--     - send_warm_request enforces single-outstanding-per-target (anti-shotgun).
--     - suggest_warm_intros excludes targets with a pending warm_request via any mutual.

begin;
select plan(6);

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
-- alice (viewer/asker), bob (mutual), carol (target), dave (second mutual).
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'carol');
select tests.make_user('44444444-4444-4444-4444-444444444444'::uuid, 'dave');

-- Seed the connection triangle: alice↔bob, alice↔dave, bob↔carol, dave↔carol.
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values
  ('11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222',
   rpad('alice→bob connected ', 100, 'x'),
   'connected'::public.intro_state, now() - interval '3 hours'),
  ('11111111-1111-1111-1111-111111111111',
   '44444444-4444-4444-4444-444444444444',
   rpad('alice→dave connected ', 100, 'x'),
   'connected'::public.intro_state, now() - interval '3 hours'),
  ('22222222-2222-2222-2222-222222222222',
   '33333333-3333-3333-3333-333333333333',
   rpad('bob→carol connected ', 100, 'x'),
   'connected'::public.intro_state, now() - interval '2 hours'),
  ('44444444-4444-4444-4444-444444444444',
   '33333333-3333-3333-3333-333333333333',
   rpad('dave→carol connected ', 100, 'x'),
   'connected'::public.intro_state, now() - interval '1 hour');

-- =============================================================================
-- Test 1: accept_intro rejects warm_request kind.
-- =============================================================================
-- Seed a delivered warm_request from alice→bob (target = carol).
insert into public.intros (
  id, sender_id, recipient_id, note, state, kind, warm_target_id
) values (
  'aaaaaaaa-bbbb-cccc-dddd-000000000001',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('alice asks bob to intro carol — fix #3 test ', 100, 'x'),
  'delivered'::public.intro_state,
  'warm_request'::public.intro_kind,
  '33333333-3333-3333-3333-333333333333'
);

-- Bob (recipient of the warm_request) tries to accept_intro — should fail.
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select throws_like(
  $$ select public.accept_intro('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid) $$,
  '%wrong intro kind%',
  '#3 accept_intro refuses warm_request kind (no silent burial of warm_target_id)'
);

-- =============================================================================
-- Test 2: decline_intro on a warm_request does NOT stamp declined_at.
-- =============================================================================
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

-- Decline the warm_request seeded above.
select isnt(
  (select public.decline_intro('aaaaaaaa-bbbb-cccc-dddd-000000000001'::uuid)),
  null,
  '#14 decline_intro on warm_request returns the updated row'
);

select is(
  (select state::text from public.intros where id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'),
  'declined',
  '#14 decline_intro on warm_request still transitions state to declined'
);

select ok(
  (select declined_at is null from public.intros where id = 'aaaaaaaa-bbbb-cccc-dddd-000000000001'),
  '#14 decline_intro on warm_request does NOT stamp declined_at (no cooldown poison)'
);

-- =============================================================================
-- Test 3: send_warm_request enforces single-outstanding-per-(asker, target).
-- Seed a fresh outstanding warm_request from alice→bob about carol, then
-- have alice attempt another warm_request via dave about the same target.
-- =============================================================================
reset role;
-- Clean slate for the per-target shotgun scenario.
delete from public.intros where kind <> 'direct'::public.intro_kind;

insert into public.intros (
  id, sender_id, recipient_id, note, state, kind, warm_target_id
) values (
  'aaaaaaaa-bbbb-cccc-dddd-000000000002',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('alice asks bob to intro carol — anti-shotgun seed ', 100, 'x'),
  'delivered'::public.intro_state,
  'warm_request'::public.intro_kind,
  '33333333-3333-3333-3333-333333333333'
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

-- Try to shotgun the same target through dave — must fail.
select throws_like(
  $$ select public.send_warm_request(
       '44444444-4444-4444-4444-444444444444'::uuid,
       '33333333-3333-3333-3333-333333333333'::uuid,
       'Hi Dave, can you please introduce me to Carol? She seems great and we share an interest in payments.'
     ) $$,
  '%warm request already pending for target%',
  '#7 send_warm_request rejects shotgun via a second mutual to the same target'
);

-- =============================================================================
-- Test 4: suggest_warm_intros excludes targets with a pending warm_request.
-- The seed above leaves alice with an outstanding warm_request about carol —
-- carol should NOT appear in alice's suggestions (regardless of mutual).
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select count(*)::int from public.suggest_warm_intros(10)
     where target_id = '33333333-3333-3333-3333-333333333333'),
  0,
  '#8 suggest_warm_intros excludes targets the asker already has a pending warm_request about'
);

select * from finish();
rollback;
