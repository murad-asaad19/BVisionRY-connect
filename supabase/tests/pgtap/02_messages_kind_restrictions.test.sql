-- pgTAP: messages.kind restrictions on direct INSERT vs. RPC-only paths.
--
-- Migration hardening rules under test:
--   * 20260606000000_rls_hardening.sql #2 — direct INSERT into public.messages
--     allowed ONLY for kind='text' as a participant; image/voice need RPC.
--   * 20260606110000_media_message_rpcs.sql — send_image_message and
--     send_voice_message inject kind='image'/'voice' rows under SECURITY DEFINER
--     after validating the conversation + storage object.

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

-- --- fixture users + conversation ------------------------------------------
select tests.make_user('11111111-1111-1111-1111-111111111111'::uuid, 'alice');
select tests.make_user('22222222-2222-2222-2222-222222222222'::uuid, 'bob');

insert into public.conversations (id, participant_a_id, participant_b_id)
values (
  'cccccccc-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222'
);

-- Seed storage fixtures BEFORE switching to authenticated role: storage.buckets
-- isn't writable from anything but the platform/admin role. storage.objects is
-- inserted up-front for the same reason — we want the row to exist regardless
-- of what the chat-media-insert RLS policy currently allows for authenticated.
insert into storage.buckets (id, name, public)
values ('chat-media', 'chat-media', false)
on conflict (id) do nothing;

insert into storage.objects (bucket_id, name, owner)
values (
  'chat-media',
  'cccccccc-1111-1111-1111-111111111111/' ||
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/photo.jpg',
  '11111111-1111-1111-1111-111111111111'
);
insert into storage.objects (bucket_id, name, owner)
values (
  'chat-media',
  'cccccccc-1111-1111-1111-111111111111/' ||
    'ffffffff-ffff-ffff-ffff-ffffffffffff/voice.m4a',
  '11111111-1111-1111-1111-111111111111'
);

-- alice will be our active sender for all five subtests.
select tests.auth_as('11111111-1111-1111-1111-111111111111'::uuid);

-- =============================================================================
-- 1. Direct INSERT with kind='text' by a participant is allowed.
-- =============================================================================
select lives_ok(
  $$ insert into public.messages (conversation_id, sender_id, kind, body)
     values ('cccccccc-1111-1111-1111-111111111111',
             '11111111-1111-1111-1111-111111111111',
             'text'::public.message_kind,
             'Hello text message') $$,
  'authenticated participant can directly insert kind=text message'
);

-- =============================================================================
-- 2. Direct INSERT with kind='image' is rejected by the WITH CHECK clause.
-- =============================================================================
select throws_ok(
  $$ insert into public.messages (conversation_id, sender_id, kind, media_path, media_size_bytes)
     values ('cccccccc-1111-1111-1111-111111111111',
             '11111111-1111-1111-1111-111111111111',
             'image'::public.message_kind,
             'cccccccc-1111-1111-1111-111111111111/' ||
               'dddddddd-dddd-dddd-dddd-dddddddddddd/photo.jpg',
             4096) $$,
  '42501',  -- new row violates RLS / WITH CHECK
  null,
  'direct INSERT of kind=image is rejected by messages_insert_participant WITH CHECK'
);

-- =============================================================================
-- 3. send_image_message RPC inserts a kind='image' row.
-- Storage objects were pre-inserted above as the superuser fixture role.
-- =============================================================================
select lives_ok(
  $$ select public.send_image_message(
       'cccccccc-1111-1111-1111-111111111111'::uuid,
       'cccccccc-1111-1111-1111-111111111111/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/photo.jpg',
       'image/jpeg',
       4096
     ) $$,
  'send_image_message RPC inserts a kind=image row with valid path'
);

select is(
  (select kind::text from public.messages
   where id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'),
  'image',
  'send_image_message persisted row has kind=image (extracted from path)'
);

-- =============================================================================
-- 4. send_voice_message RPC inserts a kind='voice' row with duration.
-- =============================================================================
select lives_ok(
  $$ select public.send_voice_message(
       'cccccccc-1111-1111-1111-111111111111'::uuid,
       'cccccccc-1111-1111-1111-111111111111/ffffffff-ffff-ffff-ffff-ffffffffffff/voice.m4a',
       'audio/m4a',
       8192,
       10000
     ) $$,
  'send_voice_message RPC inserts a kind=voice row with valid path + duration'
);

select * from finish();
rollback;
