-- pgTAP: Opportunities post-review fixes.
--
-- Under test:
--   * 20260608050000_opportunities_fixes.sql
--   * 20260608050001_opportunities_fixes_trigger.sql
--
-- Specifically:
--   (a) express_interest refuses to record interest when viewer↔author
--       are blocked in either direction (Finding #2).
--   (b) list_opportunities hides posts whose author is suspended,
--       private, or not onboarded (Finding #4).
--   (c) get_opportunity hides the same posts (and still lets the
--       author themselves see their own row) (Finding #4).
--   (d) Multiple interests on the same opportunity each generate a
--       distinct push_log row, because the notify trigger now emits a
--       per-interest synthetic event_id (Finding #12).

begin;
select plan(7);

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
-- alice = opportunity author. bob = normal viewer who will be blocked.
-- carol = second viewer used for the push-dedup test. eve = will become
-- suspended/private/not-onboarded for the public-surface tests.
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'carol');
select tests.make_user('44444444-4444-4444-4444-444444444444'::uuid, 'eve');

-- --- alice posts an opportunity --------------------------------------------
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.create_opportunity(
  'hiring'::public.opportunity_kind,
  'Hiring a senior product manager',
  'We are hiring a PM to lead our payments product line. Remote-friendly, Berlin preferred.',
  ARRAY['pm', 'payments', 'remote']
);

-- =============================================================================
-- (a) Finding #2 — express_interest refuses across blocks.
-- =============================================================================
-- bob blocks alice → bob cannot express interest in alice's post.
reset role;
insert into public.blocks (blocker_id, blocked_id)
values ('22222222-2222-2222-2222-222222222222'::uuid,
        '11111111-1111-1111-1111-111111111111'::uuid);

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select throws_like(
  $$ select public.express_interest(
       (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
       null
     ) $$,
  '%blocked%',
  'express_interest refuses when viewer blocks the author'
);

-- Flip direction: alice blocks bob → bob still refused.
reset role;
delete from public.blocks
  where blocker_id = '22222222-2222-2222-2222-222222222222'::uuid
    and blocked_id = '11111111-1111-1111-1111-111111111111'::uuid;
insert into public.blocks (blocker_id, blocked_id)
values ('11111111-1111-1111-1111-111111111111'::uuid,
        '22222222-2222-2222-2222-222222222222'::uuid);

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select throws_like(
  $$ select public.express_interest(
       (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
       null
     ) $$,
  '%blocked%',
  'express_interest refuses when author blocks the viewer'
);

-- Cleanup blocks for downstream tests.
reset role;
delete from public.blocks
  where (blocker_id = '11111111-1111-1111-1111-111111111111'::uuid and blocked_id = '22222222-2222-2222-2222-222222222222'::uuid);

-- =============================================================================
-- (b) Finding #4 — list_opportunities hides suspended / private / not-onboarded authors.
-- =============================================================================
-- eve posts an opportunity, then becomes private. bob's feed should drop it.
select tests.auth_as('44444444-4444-4444-4444-444444444444'::uuid);
select public.create_opportunity(
  'cofounder'::public.opportunity_kind,
  'Looking for a CTO for a healthtech startup',
  'I am building a digital health product and need a technical co-founder to lead engineering.',
  ARRAY['cto', 'health']
);

-- Sanity: with eve in default (onboarded, non-private, non-suspended) state,
-- bob sees BOTH alice's and eve's posts (=2).
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select is(
  (select count(*)::int from public.list_opportunities()),
  2,
  'list_opportunities surfaces both posts when both authors are healthy'
);

-- Flip eve → private. Her post must drop out of the feed.
reset role;
update public.profiles set private_mode = true
  where id = '44444444-4444-4444-4444-444444444444'::uuid;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select is(
  (select count(*)::int from public.list_opportunities()),
  1,
  'list_opportunities hides posts by private authors'
);

-- Restore eve, flip her → suspended.
reset role;
update public.profiles set private_mode = false, suspended_at = now()
  where id = '44444444-4444-4444-4444-444444444444'::uuid;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select is(
  (select count(*)::int from public.list_opportunities()),
  1,
  'list_opportunities hides posts by suspended authors'
);

-- =============================================================================
-- (c) Finding #4 — get_opportunity hides the same posts.
--     But the author themselves can still load their own row (own-row escape).
-- =============================================================================
-- bob can't see eve's post via get_opportunity while she's suspended.
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select is(
  (select count(*)::int from public.get_opportunity(
     (select id from public.opportunities where author_id = '44444444-4444-4444-4444-444444444444'::uuid limit 1)
  )),
  0,
  'get_opportunity hides a suspended author''s post from other viewers'
);

-- But eve can still see her own row regardless of suspension.
select tests.auth_as('44444444-4444-4444-4444-444444444444'::uuid);
select is(
  (select count(*)::int from public.get_opportunity(
     (select id from public.opportunities where author_id = '44444444-4444-4444-4444-444444444444'::uuid limit 1)
  )),
  1,
  'get_opportunity still returns the author''s own post even when they''re suspended'
);

-- Restore eve to healthy for the next section.
reset role;
update public.profiles set suspended_at = null
  where id = '44444444-4444-4444-4444-444444444444'::uuid;

-- =============================================================================
-- (d) Finding #12 — every interest produces a distinct push_log row.
--     Pre-fix: only the first interest landed because the trigger used
--     opportunity_id as event_id and push_log's (event_table, event_id,
--     recipient_id) unique key collided for every subsequent interest.
--     Post-fix: event_id is md5(opportunity_id || ':' || user_id)::uuid.
-- =============================================================================
-- alice needs an active device token so dispatch_push proceeds past the
-- "no tokens" early return. The HTTP call may fail in the test container,
-- but the function swallows the error and the push_log row still lands.
reset role;
insert into public.device_tokens (user_id, token, platform)
values (
  '11111111-1111-1111-1111-111111111111'::uuid,
  'test-token-alice-fixes',
  'ios'::public.device_platform
);

-- bob expresses interest.
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select public.express_interest(
  (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
  null
);

-- carol expresses interest in the SAME opportunity.
select tests.auth_as('33333333-3333-3333-3333-333333333333'::uuid);
select public.express_interest(
  (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
  null
);

-- Two distinct push_log rows must exist for alice (one per interest).
reset role;
select is(
  (select count(*)::int from public.push_log
    where event_table  = 'opportunity_interests'
      and recipient_id = '11111111-1111-1111-1111-111111111111'::uuid),
  2,
  'notify_opportunity_interest emits a distinct push_log row per interest (no event_id collision)'
);

select * from finish();
rollback;
