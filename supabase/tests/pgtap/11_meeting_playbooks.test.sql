-- pgTAP: meeting playbooks RLS + get_meeting_playbook RPC.
--
-- Under test:
--   * 20260608040000_meeting_playbooks.sql
--
-- Surface area:
--   * get_meeting_playbook returns the caller's own row when present.
--   * get_meeting_playbook returns empty when no row exists.
--   * get_meeting_playbook returns empty when the caller is NOT a meeting
--     participant (even if a row exists for a different viewer).
--   * Direct SELECT on the table from authenticated returns 0 rows (RLS).
--   * Direct INSERT on the table from authenticated raises (RLS).
--   * Cascade delete from meeting_proposals scrubs the playbook rows.

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
-- Three users so we can test the non-participant branch with a real auth ctx.
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');
select tests.make_user('33333333-3333-3333-3333-333333333333'::uuid, 'carla');

insert into public.conversations (id, participant_a_id, participant_b_id)
values (
  'cccccccc-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222'
);

-- alice proposes; bob confirms — gives us a real meeting_proposals row.
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select public.propose_meeting(
  'cccccccc-3333-3333-3333-333333333333'::uuid,
  array[now() + interval '1 day']::timestamptz[],
  30,
  null
);

reset role;

-- Insert one playbook row keyed (meeting, viewer=alice). Use service-role
-- (reset role above) so RLS doesn't block the seed.
insert into public.meeting_playbooks (
  meeting_id, viewer_id, target_id,
  summary, shared_interests, conversation_starters, do_notes, dont_notes,
  generation_input_hash
)
select
  m.id, '11111111-1111-1111-1111-111111111111'::uuid,
  '22222222-2222-2222-2222-222222222222'::uuid,
  'Bob builds payments and loves cycling.',
  array['payments', 'cycling']::text[],
  array['What got you into payments?']::text[],
  array['Lead with the cycling angle']::text[],
  array['Skip past introductions']::text[],
  'hash-v1'
  from public.meeting_proposals m
 where m.conversation_id = 'cccccccc-3333-3333-3333-333333333333'
 limit 1;

-- =============================================================================
-- 1. get_meeting_playbook returns the row when caller is a participant.
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select is(
  (
    select summary from public.get_meeting_playbook(
      (select id from public.meeting_proposals
        where conversation_id = 'cccccccc-3333-3333-3333-333333333333' limit 1)
    )
  ),
  'Bob builds payments and loves cycling.',
  'get_meeting_playbook returns the row when caller is the matching viewer participant'
);

-- =============================================================================
-- 2. get_meeting_playbook returns 0 rows when no playbook exists for caller.
-- =============================================================================
-- bob is a participant but has no playbook row yet → empty set.
select tests.auth_as('22222222-2222-2222-2222-222222222222'::uuid);
select is(
  (
    select count(*)::int from public.get_meeting_playbook(
      (select id from public.meeting_proposals
        where conversation_id = 'cccccccc-3333-3333-3333-333333333333' limit 1)
    )
  ),
  0,
  'get_meeting_playbook returns empty when no row exists for the caller-viewer'
);

-- =============================================================================
-- 3. get_meeting_playbook returns 0 rows when caller is NOT a participant.
-- =============================================================================
-- carla is not in the conversation. Even though alice's row exists,
-- the RPC must NOT return it to her.
select tests.auth_as('33333333-3333-3333-3333-333333333333'::uuid);
select is(
  (
    select count(*)::int from public.get_meeting_playbook(
      (select id from public.meeting_proposals
        where conversation_id = 'cccccccc-3333-3333-3333-333333333333' limit 1)
    )
  ),
  0,
  'get_meeting_playbook returns empty when caller is not a meeting participant'
);

-- =============================================================================
-- 4. Direct SELECT on the table from authenticated returns 0 rows (RLS).
-- =============================================================================
-- alice owns the seeded row but the table policy blocks all authenticated
-- direct access. Should see zero.
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select is(
  (select count(*)::int from public.meeting_playbooks),
  0,
  'direct SELECT on meeting_playbooks returns 0 rows under authenticated (RLS denies)'
);

-- =============================================================================
-- 5. Direct INSERT on the table from authenticated raises (RLS).
-- =============================================================================
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);
select throws_ok(
  $$ insert into public.meeting_playbooks (
       meeting_id, viewer_id, target_id,
       summary, generation_input_hash
     ) values (
       (select id from public.meeting_proposals
         where conversation_id = 'cccccccc-3333-3333-3333-333333333333' limit 1),
       '11111111-1111-1111-1111-111111111111',
       '22222222-2222-2222-2222-222222222222',
       'shouldnt land', 'h'
     ) $$,
  '42501',
  null,
  'direct INSERT on meeting_playbooks from authenticated raises RLS violation'
);

-- =============================================================================
-- 6. Cascade delete: deleting the meeting_proposal scrubs playbook rows too.
-- =============================================================================
reset role;
delete from public.meeting_proposals
 where conversation_id = 'cccccccc-3333-3333-3333-333333333333';
select is(
  (select count(*)::int from public.meeting_playbooks),
  0,
  'cascade delete from meeting_proposals removes playbook rows'
);

select * from finish();
rollback;
