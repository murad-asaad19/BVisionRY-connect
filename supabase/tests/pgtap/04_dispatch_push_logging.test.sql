-- pgTAP: dispatch_push idempotency + skip-on-no-tokens.
--
-- Under test:
--   * The canonical dispatch_push(uuid, text, uuid, jsonb, text, uuid, uuid)
--     function, currently defined by
--     20260606150000_dispatch_push_payload.sql. It:
--       - inserts into push_log (or does nothing on conflict)
--       - returns early without calling net.http_post when the recipient has no
--         active (revoked_at IS NULL) device_tokens row.
--
-- NB: the standalone 4-arg overload (uuid, text, uuid, jsonb) that previously
-- shipped in 20260521000000 / 20260606010000 was DROPPED outright in
-- 20260607030000_rls_followups.sql #2 (it survived Wave-6's revoke because
-- Postgres treats different arg counts as distinct functions, and a public
-- 4-arg form would have let any authenticated user poison push_log). The
-- 4-arg call shape used below now resolves to the 7-arg form via the three
-- defaulted trailing params (p_kind, p_entity_id, p_conversation_id) — the
-- test still exercises the same code path, just through default-arg
-- resolution rather than a separate overload.
--
-- We don't need to intercept pg_net here: the function wraps it in
-- `exception when others`, so even if the HTTP call fails the push_log row
-- still lands. The "no tokens" path returns BEFORE the HTTP call, so the
-- best signal is push_log presence + absence of error == clean skip.

begin;
select plan(5);

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

-- --- fixture ----------------------------------------------------------------
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');

-- =============================================================================
-- 1. First call inserts a push_log row.
-- =============================================================================
-- Service role is needed because dispatch_push is SECURITY DEFINER and writes
-- to push_log/device_tokens; the function itself enforces semantics.
-- pg_net's http_post may fail in the test container (no kong) — the function
-- swallows it via the exception handler, so the test still passes.
select public.dispatch_push(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'intros'::text,
  '00000000-0000-0000-0000-000000000a01'::uuid,
  '{"kind":"intro_received","title":"Hi","body":"You have a new intro.","url":"/"}'::jsonb
);

select is(
  (select count(*)::int from public.push_log
   where event_table = 'intros'
     and event_id    = '00000000-0000-0000-0000-000000000a01'
     and recipient_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'dispatch_push inserts exactly one push_log row on first call'
);

-- =============================================================================
-- 2. Repeat call is idempotent (unique constraint on tuple → ON CONFLICT DO NOTHING).
-- =============================================================================
select public.dispatch_push(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'intros'::text,
  '00000000-0000-0000-0000-000000000a01'::uuid,
  '{"kind":"intro_received","title":"dup","body":"dup","url":"/"}'::jsonb
);

select is(
  (select count(*)::int from public.push_log
   where event_table = 'intros'
     and event_id    = '00000000-0000-0000-0000-000000000a01'
     and recipient_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'dispatch_push is idempotent: second call on same (event_table, event_id, recipient) does NOT duplicate'
);

-- =============================================================================
-- 3. With no active device_tokens, dispatch_push skips the HTTP call but the
--    push_log row still lands. We can assert that no `error` column was
--    populated (a successful net.http_post failure inside the exception
--    handler would set error = SQLERRM).
-- =============================================================================
select is(
  (select error from public.push_log
   where event_table = 'intros'
     and event_id    = '00000000-0000-0000-0000-000000000a01'
     and recipient_id = '11111111-1111-1111-1111-111111111111'),
  null,
  'no http_post attempted when recipient has zero active device_tokens (error column null)'
);

-- =============================================================================
-- 4. Add a revoked device_token; recipient still counts as having no active
--    tokens, so behaviour is unchanged on a new event_id.
-- =============================================================================
insert into public.device_tokens (user_id, token, platform, revoked_at)
values (
  '11111111-1111-1111-1111-111111111111',
  'revoked-token-of-sufficient-length-aaaa',
  'ios'::public.device_platform,
  now() - interval '1 day'
);

select public.dispatch_push(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'intros'::text,
  '00000000-0000-0000-0000-000000000a02'::uuid,
  '{"kind":"intro_received","title":"hi","body":"hi","url":"/"}'::jsonb
);

select is(
  (select count(*)::int from public.push_log
   where event_table = 'intros'
     and event_id    = '00000000-0000-0000-0000-000000000a02'
     and recipient_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'dispatch_push still logs to push_log even when only revoked tokens exist'
);

-- =============================================================================
-- 5. Insert an ACTIVE device_token; second call still logs (idempotent unique).
--    The HTTP attempt is best-effort and the unit test cannot intercept pg_net
--    in this container; the function`s exception handler swallows the failure.
--    We assert the log row still exists with no duplicate after both calls —
--    NOTE: the push_log.error column may be populated when pg_net synchronously
--    raises (queue not ready, unreachable URL), so this test intentionally
--    does NOT assert error IS NULL on this row.
-- =============================================================================
insert into public.device_tokens (user_id, token, platform)
values (
  '11111111-1111-1111-1111-111111111111',
  'active-token-of-sufficient-length-bbbb',
  'ios'::public.device_platform
);

select public.dispatch_push(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'intros'::text,
  '00000000-0000-0000-0000-000000000a03'::uuid,
  '{"kind":"intro_received","title":"hi","body":"hi","url":"/"}'::jsonb
);
select public.dispatch_push(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'intros'::text,
  '00000000-0000-0000-0000-000000000a03'::uuid,
  '{"kind":"intro_received","title":"hi","body":"hi","url":"/"}'::jsonb
);

select is(
  (select count(*)::int from public.push_log
   where event_table = 'intros'
     and event_id    = '00000000-0000-0000-0000-000000000a03'
     and recipient_id = '11111111-1111-1111-1111-111111111111'),
  1,
  'dispatch_push remains idempotent on second call when active token present'
);

select * from finish();
rollback;
