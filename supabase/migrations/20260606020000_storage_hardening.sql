-- Storage policy hardening: owner-scoped chat-media writes, sender+conversation match on INSERT,
-- WITH CHECK on avatars UPDATE.

-- ============================================================
-- #4  chat-media: tighten INSERT, add owner-scoped UPDATE/DELETE
-- Path layout (mobile/src/features/media/services/storage.service.ts):
--   {conversationId}/{messageId}/{uniq}.{ext}
-- Auth ties:
--   * messageId must reference a row authored by auth.uid()
--   * conversationId must match the message's conversation_id
-- NOTE: depends on direct client INSERT of image/voice messages (currently allowed by RLS
-- but blocked starting from rls_hardening migration #2). Follow-up RPCs are required —
-- see TODO in 20260606000000_rls_hardening.sql.
-- ============================================================
drop policy if exists "chat-media-insert" on storage.objects;
create policy "chat-media-insert" on storage.objects for insert
  with check (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.messages m
      where m.id::text = (storage.foldername(name))[2]
        and m.sender_id = auth.uid()
        and m.conversation_id::text = (storage.foldername(name))[1]
    )
  );

drop policy if exists "chat-media-update" on storage.objects;
create policy "chat-media-update" on storage.objects for update
  using (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.messages m
      where m.id::text = (storage.foldername(name))[2]
        and m.sender_id = auth.uid()
        and m.conversation_id::text = (storage.foldername(name))[1]
    )
  )
  with check (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.messages m
      where m.id::text = (storage.foldername(name))[2]
        and m.sender_id = auth.uid()
        and m.conversation_id::text = (storage.foldername(name))[1]
    )
  );

drop policy if exists "chat-media-delete" on storage.objects;
create policy "chat-media-delete" on storage.objects for delete
  using (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.messages m
      where m.id::text = (storage.foldername(name))[2]
        and m.sender_id = auth.uid()
        and m.conversation_id::text = (storage.foldername(name))[1]
    )
  );

-- ============================================================
-- #5  avatars: add WITH CHECK to UPDATE (DELETE has no WITH CHECK clause in Postgres RLS)
-- ============================================================
drop policy if exists "avatars-update" on storage.objects;
create policy "avatars-update" on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- avatars-delete: USING already enforces the owner check; Postgres DELETE policies
-- do not accept WITH CHECK, so no change required here.

-- ============================================================
-- Summary of changes in this migration
-- ============================================================
-- #4 chat-media: INSERT now requires message row owned by auth.uid() with matching
--    conversation_id; UPDATE and DELETE policies added with identical owner-scoping.
-- #5 avatars-update: WITH CHECK added (DELETE policy unchanged — no WITH CHECK clause).
