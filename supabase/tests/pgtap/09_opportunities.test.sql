-- pgTAP: Opportunities board.
--
-- Under test:
--   * 20260608020000_opportunities.sql — opportunities + opportunity_interests
--     tables, list / get / create / update / close / express_interest /
--     list_my_opportunities / list_interested RPCs, and the
--     notify_opportunity_interest trigger.

begin;
select plan(15);

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
-- alice = author of most opportunities, bob/carol = viewers, dave = blocked.
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'carol');
select tests.make_user('44444444-4444-4444-4444-444444444444'::uuid, 'dave');

-- =============================================================================
-- 1. create_opportunity: title too short → 22023.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select throws_like(
  $$ select public.create_opportunity(
       'hiring'::public.opportunity_kind,
       'tiny',
       'A sufficiently long body for the post that should easily clear the lower bound.',
       '{}'::text[]
     ) $$,
  '%title must be 5-120 characters%',
  'create_opportunity rejects titles shorter than 5 characters'
);

-- =============================================================================
-- 2. create_opportunity: body too short → 22023.
-- =============================================================================
select throws_like(
  $$ select public.create_opportunity(
       'hiring'::public.opportunity_kind,
       'Hiring a senior product manager',
       'short',
       '{}'::text[]
     ) $$,
  '%body must be 10-2000 characters%',
  'create_opportunity rejects bodies shorter than 10 characters'
);

-- =============================================================================
-- 3. create_opportunity: too many tags → 22023.
-- =============================================================================
select throws_like(
  $$ select public.create_opportunity(
       'hiring'::public.opportunity_kind,
       'Hiring a senior product manager',
       'A sufficiently long body for the post that should easily clear the lower bound.',
       ARRAY['a','b','c','d','e','f','g','h','i']
     ) $$,
  '%at most 8 tags allowed%',
  'create_opportunity rejects more than 8 tags'
);

-- =============================================================================
-- 4. create_opportunity happy path; feed excludes own posts for the author.
-- =============================================================================
select isnt(
  (select public.create_opportunity(
     'hiring'::public.opportunity_kind,
     'Hiring a senior product manager',
     'We are hiring a PM to lead our payments product line. Remote-friendly, Berlin preferred.',
     ARRAY['pm', 'payments', 'remote']
   )),
  null,
  'create_opportunity returns a new id on the happy path'
);

select is(
  (select count(*)::int from public.list_opportunities()),
  0,
  'list_opportunities excludes the caller''s own posts'
);

-- =============================================================================
-- 5. Other viewers see the opportunity in their feed.
-- =============================================================================
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select is(
  (select count(*)::int from public.list_opportunities()),
  1,
  'list_opportunities surfaces alice''s post to bob'
);

-- =============================================================================
-- 6. kind filter narrows the feed (fundraising kind filter on a hiring post).
-- =============================================================================
select is(
  (select count(*)::int from public.list_opportunities(
     ARRAY['fundraising'::public.opportunity_kind]
   )),
  0,
  'list_opportunities filters by kind (fundraising filter excludes hiring post)'
);

-- =============================================================================
-- 7. Blocked viewer (carol blocks alice) does not see alice's post.
-- =============================================================================
reset role;
insert into public.blocks (blocker_id, blocked_id)
values ('33333333-3333-3333-3333-333333333333'::uuid,
        '11111111-1111-1111-1111-111111111111'::uuid);

select tests.auth_as('33333333-3333-3333-3333-333333333333'::uuid);

select is(
  (select count(*)::int from public.list_opportunities()),
  0,
  'list_opportunities excludes posts from blocked authors'
);

-- Clear block for downstream tests.
reset role;
delete from public.blocks
 where blocker_id = '33333333-3333-3333-3333-333333333333'::uuid
   and blocked_id = '11111111-1111-1111-1111-111111111111'::uuid;

-- =============================================================================
-- 8. Closed opportunities are excluded from the feed.
-- =============================================================================
reset role;
update public.opportunities
   set status = 'closed'::public.opportunity_status,
       closed_at = now()
 where author_id = '11111111-1111-1111-1111-111111111111'::uuid;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select is(
  (select count(*)::int from public.list_opportunities()),
  0,
  'list_opportunities excludes closed opportunities'
);

-- Re-open for downstream tests.
reset role;
update public.opportunities
   set status = 'open'::public.opportunity_status,
       closed_at = null
 where author_id = '11111111-1111-1111-1111-111111111111'::uuid;

-- =============================================================================
-- 9. Expired opportunities are excluded from the feed.
-- =============================================================================
reset role;
update public.opportunities
   set expires_at = now() - interval '1 day'
 where author_id = '11111111-1111-1111-1111-111111111111'::uuid;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select is(
  (select count(*)::int from public.list_opportunities()),
  0,
  'list_opportunities excludes expired opportunities'
);

reset role;
update public.opportunities
   set expires_at = now() + interval '30 days'
 where author_id = '11111111-1111-1111-1111-111111111111'::uuid;

-- =============================================================================
-- 10. update_opportunity rejects callers other than the author.
-- =============================================================================
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select throws_like(
  $$ select public.update_opportunity(
       (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
       'hiring'::public.opportunity_kind,
       'A different title for the opportunity post',
       'Body for the updated post that is long enough to satisfy validation rules.',
       '{}'::text[]
     ) $$,
  '%not owned by caller%',
  'update_opportunity rejects callers other than the author'
);

-- =============================================================================
-- 11. close_opportunity rejects callers other than the author.
-- =============================================================================
select throws_like(
  $$ select public.close_opportunity(
       (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1)
     ) $$,
  '%not owned by caller%',
  'close_opportunity rejects callers other than the author'
);

-- =============================================================================
-- 12. close_opportunity succeeds for the author; status flips to closed.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

select lives_ok(
  $$ select public.close_opportunity(
       (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1)
     ) $$,
  'close_opportunity succeeds for the opportunity author'
);

select is(
  (select status::text from public.opportunities
    where author_id = '11111111-1111-1111-1111-111111111111'::uuid
    limit 1),
  'closed',
  'close_opportunity flips status to closed'
);

-- =============================================================================
-- 13. express_interest on a closed opportunity raises.
-- =============================================================================
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select throws_like(
  $$ select public.express_interest(
       (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
       null
     ) $$,
  '%opportunity is not open%',
  'express_interest rejects when the opportunity is not open'
);

-- =============================================================================
-- 14. express_interest is idempotent on (opportunity, user).
--     Re-open the opportunity, express interest twice, only one row exists.
-- =============================================================================
reset role;
update public.opportunities
   set status    = 'open'::public.opportunity_status,
       closed_at = null
 where author_id = '11111111-1111-1111-1111-111111111111'::uuid;

select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);

select public.express_interest(
  (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
  null
);
select public.express_interest(
  (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1),
  null
);

select is(
  (select count(*)::int from public.opportunity_interests
    where opportunity_id = (
      select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1
    )
      and user_id = '22222222-2222-2222-2222-222222222222'::uuid),
  1,
  'express_interest is idempotent — second call is a no-op'
);

-- =============================================================================
-- 15. list_interested rejects callers other than the author.
-- =============================================================================
select throws_like(
  $$ select * from public.list_interested(
       (select id from public.opportunities where author_id = '11111111-1111-1111-1111-111111111111'::uuid limit 1)
     ) $$,
  '%only the author can view interested users%',
  'list_interested rejects callers other than the author'
);

select * from finish();
rollback;
