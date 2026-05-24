-- pgTAP: 2nd-degree warm-intro suggestions.
--
-- Under test:
--   * 20260608010000_second_degree_intros.sql — intro_kind enum,
--     warm_target_id column, and the three RPCs:
--       - suggest_warm_intros
--       - send_warm_request
--       - forward_warm_intro

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
-- alice (viewer), bob (mutual), carol (target), dave (second mutual), eve (unrelated).
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'carol');
select tests.make_user('44444444-4444-4444-4444-444444444444'::uuid, 'dave');
select tests.make_user('55555555-5555-5555-5555-555555555555'::uuid, 'eve');

-- =============================================================================
-- 1. suggest_warm_intros returns nothing when the viewer has no connections.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select count(*)::int from public.suggest_warm_intros(10)),
  0,
  'suggest_warm_intros returns 0 rows when the viewer has no connections'
);

-- =============================================================================
-- Set up a triangle: alice↔bob connected, bob↔carol connected.
-- =============================================================================
reset role;

-- alice ↔ bob connected
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('alice→bob connected intro note ', 100, 'x'),
  'connected'::public.intro_state,
  now() - interval '2 hours'
);

-- bob ↔ carol connected (carol is reachable via bob)
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values (
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  rpad('bob→carol connected intro note ', 100, 'x'),
  'connected'::public.intro_state,
  now() - interval '1 hour'
);

-- =============================================================================
-- 2. suggest_warm_intros surfaces carol via bob with mutual_count = 1.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select target_id from public.suggest_warm_intros(10) limit 1),
  '33333333-3333-3333-3333-333333333333'::uuid,
  'suggest_warm_intros surfaces carol as the candidate target'
);

select is(
  (select mutual_count from public.suggest_warm_intros(10) limit 1),
  1,
  'suggest_warm_intros reports mutual_count = 1 for carol (only bob)'
);

-- =============================================================================
-- 3. Add dave↔carol so dave is also a mutual. mutual_count for carol becomes 2.
-- =============================================================================
reset role;

-- alice ↔ dave connected
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values (
  '11111111-1111-1111-1111-111111111111',
  '44444444-4444-4444-4444-444444444444',
  rpad('alice→dave connected intro note ', 100, 'x'),
  'connected'::public.intro_state,
  now() - interval '3 hours'
);

-- dave ↔ carol connected (more recent than bob ↔ carol — dave should rank as top_mutual)
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values (
  '44444444-4444-4444-4444-444444444444',
  '33333333-3333-3333-3333-333333333333',
  rpad('dave→carol connected intro note ', 100, 'x'),
  'connected'::public.intro_state,
  now()
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select mutual_count from public.suggest_warm_intros(10) where target_id = '33333333-3333-3333-3333-333333333333'),
  2,
  'mutual_count = 2 once dave also connects to carol'
);

select is(
  (select top_mutual_id from public.suggest_warm_intros(10) where target_id = '33333333-3333-3333-3333-333333333333'),
  '44444444-4444-4444-4444-444444444444'::uuid,
  'top_mutual_id picks the most-recently-connected mutual (dave)'
);

-- =============================================================================
-- 4. suggest_warm_intros excludes a target the viewer already has an intros row with.
--    Seed alice→carol declined; suggest should drop carol.
-- =============================================================================
reset role;
insert into public.intros (sender_id, recipient_id, note, state, created_at, updated_at)
values (
  '11111111-1111-1111-1111-111111111111',
  '33333333-3333-3333-3333-333333333333',
  rpad('seed alice→carol prior intro note ', 100, 'x'),
  'declined'::public.intro_state,
  now() - interval '10 days',
  now() - interval '10 days'
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select count(*)::int from public.suggest_warm_intros(10) where target_id = '33333333-3333-3333-3333-333333333333'),
  0,
  'suggest_warm_intros excludes carol once alice has any prior intros row with her'
);

-- Clean it up so subsequent scenarios still see carol as a candidate.
reset role;
delete from public.intros
 where sender_id    = '11111111-1111-1111-1111-111111111111'
   and recipient_id = '33333333-3333-3333-3333-333333333333'
   and state        = 'declined'::public.intro_state;

-- =============================================================================
-- 5. suggest_warm_intros excludes a target the viewer has blocked.
-- =============================================================================
reset role;
insert into public.blocks (blocker_id, blocked_id)
values (
  '11111111-1111-1111-1111-111111111111',
  '33333333-3333-3333-3333-333333333333'
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select count(*)::int from public.suggest_warm_intros(10) where target_id = '33333333-3333-3333-3333-333333333333'),
  0,
  'suggest_warm_intros excludes blocked targets'
);

-- Clear the block so later scenarios aren't affected.
reset role;
delete from public.blocks where blocker_id = '11111111-1111-1111-1111-111111111111';

-- =============================================================================
-- 6. send_warm_request rejects when viewer ↔ mutual is not a connection.
--    Eve has no connections — alice asking eve to forward should fail.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select throws_like(
  $$ select public.send_warm_request(
       '55555555-5555-5555-5555-555555555555'::uuid,
       '33333333-3333-3333-3333-333333333333'::uuid,
       'Hi Eve, please introduce me to Carol; we share an interest in payments and developer infra.'
     ) $$,
  '%no connection to mutual%',
  'send_warm_request rejects when viewer↔mutual is not a connection'
);

-- =============================================================================
-- 7. send_warm_request rejects when mutual ↔ target is not a connection.
--    alice↔bob is a connection, but bob is not connected to eve.
-- =============================================================================
select throws_like(
  $$ select public.send_warm_request(
       '22222222-2222-2222-2222-222222222222'::uuid,
       '55555555-5555-5555-5555-555555555555'::uuid,
       'Hi Bob, please introduce me to Eve; we share an interest in payments and developer infra.'
     ) $$,
  '%mutual has no connection to target%',
  'send_warm_request rejects when mutual↔target is not a connection'
);

-- =============================================================================
-- 8. send_warm_request enforces the daily outbound cap (shared with send_intro).
--    Wipe alice's outbound history, seed 20 fresh outbound intros from alice
--    today, then attempt one more warm_request → cap should fire.
-- =============================================================================
reset role;
delete from public.intros where sender_id = '11111111-1111-1111-1111-111111111111';

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

-- Restore the alice↔bob and bob↔carol connection rows that the wipe above removed,
-- so the triangle check passes and the daily-cap check is the failing one.
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('alice→bob re-seed connected ', 100, 'x'),
  'connected'::public.intro_state,
  now() - interval '2 hours'
);

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select throws_like(
  $$ select public.send_warm_request(
       '22222222-2222-2222-2222-222222222222'::uuid,
       '33333333-3333-3333-3333-333333333333'::uuid,
       'Hi Bob, can you please introduce me to Carol? She seems great and we share an interest.'
     ) $$,
  '%daily cap%',
  'send_warm_request honours the daily outbound cap (counts in same bucket as send_intro)'
);

-- =============================================================================
-- 9. forward_warm_intro: only the recipient of the warm_request can forward.
--    Seed a fresh warm_request (alice → bob, target carol) and have carol try
--    to forward it — should fail.
-- =============================================================================
reset role;
delete from public.intros;

-- Re-seed triangle: alice↔bob connected, bob↔carol connected.
insert into public.intros (sender_id, recipient_id, note, state, updated_at)
values
  ('11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222',
   rpad('alice→bob connected ', 100, 'x'),
   'connected'::public.intro_state, now() - interval '2 hours'),
  ('22222222-2222-2222-2222-222222222222',
   '33333333-3333-3333-3333-333333333333',
   rpad('bob→carol connected ', 100, 'x'),
   'connected'::public.intro_state, now() - interval '1 hour');

-- Insert the warm_request directly so we control its id.
insert into public.intros (
  id, sender_id, recipient_id, note, state, kind, warm_target_id
) values (
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  rpad('alice asks bob to intro carol ', 100, 'x'),
  'delivered'::public.intro_state,
  'warm_request'::public.intro_kind,
  '33333333-3333-3333-3333-333333333333'
);

-- Carol (not the recipient) tries to forward → 42501.
select tests.auth_as('33333333-3333-3333-3333-333333333333'::uuid);

select throws_like(
  $$ select public.forward_warm_intro(
       'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'::uuid,
       'Hi Carol, meet my friend Alice — she is doing some really interesting work in payments.'
     ) $$,
  '%only the warm-request recipient can forward%',
  'forward_warm_intro rejects callers other than the warm_request recipient'
);

-- =============================================================================
-- 10. forward_warm_intro: happy path — bob forwards to carol.
--     Creates a new warm_forward intro, marks the warm_request connected.
-- =============================================================================
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select isnt(
  (select public.forward_warm_intro(
     'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'::uuid,
     'Hi Carol, meet my friend Alice — she is doing some really interesting work in payments.'
   )),
  null,
  'forward_warm_intro returns a new intro id'
);

-- The original warm_request should now be closed out as connected.
select is(
  (select state::text from public.intros where id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
  'connected',
  'forward_warm_intro marks the original warm_request as connected'
);

-- A new warm_forward exists: sender=alice, recipient=carol, warm_target_id=bob (back-ref).
select is(
  (select count(*)::int from public.intros
    where sender_id      = '11111111-1111-1111-1111-111111111111'
      and recipient_id   = '33333333-3333-3333-3333-333333333333'
      and kind           = 'warm_forward'::public.intro_kind
      and warm_target_id = '22222222-2222-2222-2222-222222222222'
      and state          = 'delivered'::public.intro_state),
  1,
  'forward_warm_intro inserts a warm_forward intro (asker→target) with mutual back-ref'
);

-- =============================================================================
-- 11. forward_warm_intro rejects when the warm_request is not in delivered state.
--     The previous test just marked it connected; calling forward again must fail.
-- =============================================================================
select throws_like(
  $$ select public.forward_warm_intro(
       'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'::uuid,
       'Hi Carol, meet my friend Alice again — already connected, this should bounce.'
     ) $$,
  '%warm request not in delivered state%',
  'forward_warm_intro rejects when the warm_request has already been closed out'
);

select * from finish();
rollback;
