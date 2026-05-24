-- pgTAP: intro lifecycle (send_intro / decline_intro / accept_intro)
--
-- Covers the rules in:
--   * 20260518000000_slice4_intros.sql            (base RPCs)
--   * 20260606000000_rls_hardening.sql            (accept_intro blocks-check)
--   * 20260606080000_intros_fixes.sql             (cooldown + daily cap + declined_at)
--
-- Pattern: every scenario inserts its own fixture users via tests.make_user
-- and re-authenticates via tests.authenticate_as. The transaction is rolled
-- back at the end, so the helpers and data vanish together.

begin;
select plan(8);

-- --- inline fixture helpers (rolled back with the test transaction) ---------
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

-- NB: NOT security definer — the test session already runs as a superuser
-- that can set role to 'authenticated' directly, and a SECURITY DEFINER
-- frame can clobber `set local role` when it unwinds.
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
-- Two well-known UUIDs picked so a<b for canonical_order downstream.
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');

-- =============================================================================
-- 1. send_intro is blocked when a 30-day decline cooldown is active.
-- =============================================================================
-- Pre-seed a declined intro from alice → bob 5 days ago.
insert into public.intros (
  sender_id, recipient_id, note, state, declined_at, created_at, updated_at
) values (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('seed declined intro filler text ', 100, 'x'),
  'declined'::public.intro_state,
  now() - interval '5 days',
  now() - interval '5 days',
  now() - interval '5 days'
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select throws_like(
  $$ select public.send_intro(
       '22222222-2222-2222-2222-222222222222'::uuid,
       'Hi Bob, this is a sufficiently long intro to bypass the length check and trigger the cooldown.'
     ) $$,
  '%cooldown%',
  'send_intro raises cooldown error when a decline is < 30 days old'
);

-- =============================================================================
-- 2. send_intro is blocked when the 20/day outbound cap is reached.
-- =============================================================================
-- Wipe the declined seed row so it doesn't trigger the cooldown for cycle 2.
-- IMPORTANT: reset role first so the DELETE is not RLS-filtered to a no-op.
reset role;
delete from public.intros;

-- Make 20 fresh outgoing intros today as alice to 20 brand-new recipients.
do $$
declare
  v_recipient uuid;
  v_i int;
begin
  for v_i in 1..20 loop
    v_recipient := gen_random_uuid();
    perform tests.make_user(v_recipient, 'cap' || v_i::text);
    insert into public.intros (sender_id, recipient_id, note)
    values (
      '11111111-1111-1111-1111-111111111111',
      v_recipient,
      rpad('cap pre-seed note ' || v_i::text || ' ', 100, 'x')
    );
  end loop;
end $$;

-- 21st send (to bob) should fail with the daily-cap error.
select throws_like(
  $$ select public.send_intro(
       '22222222-2222-2222-2222-222222222222'::uuid,
       'Hi Bob, this is a sufficiently long intro to bypass the length check and trip the daily cap.'
     ) $$,
  '%daily cap%',
  'send_intro raises daily-cap error after 20 sends in current calendar day'
);

-- =============================================================================
-- 3. decline_intro stamps declined_at on the row.
-- =============================================================================
-- Reset role so the DELETE is not RLS-filtered to a no-op (RLS has no DELETE
-- policy on intros for the authenticated role).
reset role;
delete from public.intros;

-- Charlie sends to bob; bob declines.
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'charlie');

insert into public.intros (id, sender_id, recipient_id, note)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '33333333-3333-3333-3333-333333333333',
  '22222222-2222-2222-2222-222222222222',
  rpad('decline-me intro long enough ', 100, 'x')
);

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select public.decline_intro('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid);

select is(
  (select state::text from public.intros where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'declined',
  'decline_intro transitions state to declined'
);

select isnt(
  (select declined_at from public.intros where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  null,
  'decline_intro stamps declined_at'
);

-- =============================================================================
-- 4. accept_intro creates a conversation and transitions to 'connected'.
-- =============================================================================
reset role;
delete from public.intros;
delete from public.conversations;

insert into public.intros (id, sender_id, recipient_id, note)
values (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('accept-me intro long enough ', 100, 'x')
);

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select public.accept_intro('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid);

select is(
  (select state::text from public.intros where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  'connected',
  'accept_intro transitions state to connected'
);

select isnt(
  (select conversation_id from public.intros where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  null,
  'accept_intro stamps conversation_id on the intro'
);

select is(
  (select count(*)::int from public.conversations
   where (participant_a_id = '11111111-1111-1111-1111-111111111111'
          and participant_b_id = '22222222-2222-2222-2222-222222222222')
      or (participant_a_id = '22222222-2222-2222-2222-222222222222'
          and participant_b_id = '11111111-1111-1111-1111-111111111111')),
  1,
  'accept_intro creates exactly one conversation between the pair'
);

-- =============================================================================
-- 5. accept_intro raises when a block exists between sender and recipient.
-- =============================================================================
reset role;
delete from public.intros;
delete from public.conversations;
delete from public.blocks;

insert into public.intros (id, sender_id, recipient_id, note)
values (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('block-check intro long enough ', 100, 'x')
);

-- alice blocked bob (or vice-versa) — either direction should trip the check.
insert into public.blocks (blocker_id, blocked_id)
values ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select throws_like(
  $$ select public.accept_intro('cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid) $$,
  '%blocked%',
  'accept_intro raises when a block exists between sender and recipient'
);

select * from finish();
rollback;
