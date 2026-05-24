-- pgTAP: mark_conversation_read writes regardless of read_receipts_enabled,
--        and is gated on participant membership.
--
-- Under test:
--   * 20260606010000_schema_fixes.sql #7 — original implementation that
--     short-circuited when read_receipts_enabled was false.
--   * Wave-6 (20260607000000_security_hardening.sql) — removed the
--     read_receipts short-circuit; the row backing the caller's OWN unread
--     badge must always be written. Cross-user read receipts are a separate
--     feature that will consult read_receipts_enabled at broadcast time.
--   * Wave-7 (20260607030000_rls_followups.sql #3) — re-added a participant
--     gate before the upsert so an authenticated user cannot insert junk
--     conversation_reads rows for arbitrary conversation UUIDs.
--
-- This test therefore exercises:
--   1. read_receipts_enabled=false (the column default) STILL writes a row
--      (Wave-6 removed the short-circuit).
--   2. read_receipts_enabled=true ALSO writes a row (sanity check).
--   3. list_conversation_unread reflects unread=2 before mark, 0 after.
--   4. A non-participant calling mark_conversation_read on a foreign
--      conversation UUID raises 42501 (Wave-7 participant guard).

begin;
select plan(6);

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
-- Third user (charlie) is a NON-participant of the conversation below, used
-- in the Wave-7 participant-guard assertion at the end.
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'charlie');

insert into public.conversations (id, participant_a_id, participant_b_id)
values (
  'cccccccc-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222'
);

-- Two text messages from bob → conversation. unread_count for alice should be 2.
insert into public.messages (conversation_id, sender_id, kind, body, created_at)
values
  ('cccccccc-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   'text'::public.message_kind, 'Hi alice', now() - interval '5 minutes'),
  ('cccccccc-2222-2222-2222-222222222222',
   '22222222-2222-2222-2222-222222222222',
   'text'::public.message_kind, 'You there?', now() - interval '1 minute');


-- =============================================================================
-- 1. read_receipts_enabled = false (the column default) → row IS written.
--    Wave-6 removed the read_receipts short-circuit: the row backing the
--    caller's OWN unread badge must always be written. read_receipts only
--    gates the (not-yet-implemented) cross-user broadcast.
-- =============================================================================
-- alice's profile keeps the default `read_receipts_enabled = false`.
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.mark_conversation_read('cccccccc-2222-2222-2222-222222222222'::uuid);

select is(
  (select count(*)::int from public.conversation_reads
   where user_id = '11111111-1111-1111-1111-111111111111'
     and conversation_id = 'cccccccc-2222-2222-2222-222222222222'),
  1,
  'mark_conversation_read writes a row regardless of read_receipts_enabled (Wave-6)'
);

-- =============================================================================
-- 2. Flip read_receipts_enabled = true → row IS written (sanity).
-- =============================================================================
-- Switch out of authenticated role temporarily to bypass column-level UPDATE
-- revoke on sensitive cols (read_receipts_enabled isn't in the revoke list,
-- but using service_role keeps the test isolated from policy mistakes).
reset role;
update public.profiles
   set read_receipts_enabled = true
 where id = '11111111-1111-1111-1111-111111111111';

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.mark_conversation_read('cccccccc-2222-2222-2222-222222222222'::uuid);

select is(
  (select count(*)::int from public.conversation_reads
   where user_id = '11111111-1111-1111-1111-111111111111'
     and conversation_id = 'cccccccc-2222-2222-2222-222222222222'),
  1,
  'mark_conversation_read writes a row when read_receipts_enabled = true'
);

-- =============================================================================
-- 3. list_conversation_unread reflects unread = 2 before mark, 0 after.
-- =============================================================================
-- Pretend alice has not yet read by deleting the row we just wrote.
reset role;
delete from public.conversation_reads
 where user_id = '11111111-1111-1111-1111-111111111111';

select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select is(
  (select unread_count from public.list_conversation_unread()
   where conversation_id = 'cccccccc-2222-2222-2222-222222222222'),
  2,
  'list_conversation_unread reports 2 unread messages before mark'
);

-- mark with receipts enabled (still true from step 2)
select public.mark_conversation_read('cccccccc-2222-2222-2222-222222222222'::uuid);

select is(
  (select unread_count from public.list_conversation_unread()
   where conversation_id = 'cccccccc-2222-2222-2222-222222222222'),
  0,
  'list_conversation_unread reports 0 after mark_conversation_read'
);

-- =============================================================================
-- 4. Non-participant → 42501. Wave-7 (20260607030000) added a participant
--    guard before the upsert. Without it any authenticated user could
--    INSERT a conversation_reads row for any conversation UUID; the PK
--    only collapses duplicates, it doesn't authorize the write.
-- =============================================================================
select tests.auth_as('33333333-3333-3333-3333-333333333333'::uuid);

select throws_ok(
  $$ select public.mark_conversation_read('cccccccc-2222-2222-2222-222222222222'::uuid) $$,
  '42501',
  null,
  'mark_conversation_read raises 42501 when caller is not a conversation participant'
);

-- Defensive: confirm no row landed under charlie's id.
reset role;
select is(
  (select count(*)::int from public.conversation_reads
   where user_id = '33333333-3333-3333-3333-333333333333'
     and conversation_id = 'cccccccc-2222-2222-2222-222222222222'),
  0,
  'no conversation_reads row written for the non-participant'
);

select * from finish();
rollback;
