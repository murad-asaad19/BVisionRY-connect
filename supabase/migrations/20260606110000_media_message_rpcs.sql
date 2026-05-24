-- Media message RPCs (SECURITY DEFINER) — restore image/voice message flow
-- after rls_hardening migration #2 restricted direct client INSERT into
-- public.messages to kind='text'. The client must now:
--   1) Generate messageId client-side (crypto.randomUUID()).
--   2) Upload to chat-media at `{conversationId}/{messageId}/{filename}`.
--   3) Call send_image_message / send_voice_message with the real path.
--
-- The RPCs:
--   * Verify caller is a participant in the conversation.
--   * Verify the storage object exists and is owned by the caller.
--   * Extract message_id from the path's second folder and insert the row
--     with that explicit id, so the existing chat-media-update / -delete
--     storage policies (which key on `messages.id::text = foldername[2]`)
--     continue to match for cleanup.

-- ============================================================
-- #1  Relax chat-media-insert: participant-scoped (upload precedes message row)
-- The hardened policy in 20260606020000_storage_hardening.sql required a
-- message row to exist BEFORE the upload, which is incompatible with the
-- atomic upload-then-RPC pattern. Replace it with a participant check.
-- UPDATE/DELETE still key on the message row for ownership.
-- ============================================================
drop policy if exists "chat-media-insert" on storage.objects;
create policy "chat-media-insert" on storage.objects for insert
  with check (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.conversations c
      where c.id::text = (storage.foldername(name))[1]
        and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
    )
  );

-- ============================================================
-- #2  send_image_message — atomic insert of kind='image' message
-- ============================================================
create or replace function public.send_image_message(
  p_conversation_id uuid,
  p_media_path text,
  p_media_mime text,
  p_media_size_bytes int
)
returns public.messages
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  v_caller uuid := auth.uid();
  v_folders text[];
  v_msg_id uuid;
  v_msg public.messages;
begin
  if v_caller is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_conversation_id is null then
    raise exception 'conversation_id required' using errcode = '22023';
  end if;
  if p_media_path is null or length(p_media_path) = 0 then
    raise exception 'media_path required' using errcode = '22023';
  end if;
  if p_media_size_bytes is null or p_media_size_bytes <= 0 then
    raise exception 'media_size_bytes required' using errcode = '22023';
  end if;
  if p_media_size_bytes > 5 * 1024 * 1024 then
    raise exception 'image exceeds 5MB limit' using errcode = '22023';
  end if;

  -- Validate path layout: {conversationId}/{messageId}/{filename}
  v_folders := storage.foldername(p_media_path);
  if v_folders is null or array_length(v_folders, 1) <> 2 then
    raise exception 'invalid media_path layout' using errcode = '22023';
  end if;
  if v_folders[1] <> p_conversation_id::text then
    raise exception 'media_path conversation mismatch' using errcode = '22023';
  end if;

  begin
    v_msg_id := v_folders[2]::uuid;
  exception when others then
    raise exception 'media_path message_id segment must be a uuid' using errcode = '22023';
  end;

  -- Caller must be a participant in the conversation
  if not exists (
    select 1 from public.conversations c
    where c.id = p_conversation_id
      and (c.participant_a_id = v_caller or c.participant_b_id = v_caller)
  ) then
    raise exception 'not a participant' using errcode = '42501';
  end if;

  -- Caller must have uploaded the storage object
  if not exists (
    select 1 from storage.objects
    where bucket_id = 'chat-media'
      and name = p_media_path
      and owner = v_caller
  ) then
    raise exception 'media object not found or not owned by caller'
      using errcode = '42501';
  end if;

  insert into public.messages (
    id,
    conversation_id,
    sender_id,
    kind,
    media_path,
    media_size_bytes
  ) values (
    v_msg_id,
    p_conversation_id,
    v_caller,
    'image'::public.message_kind,
    p_media_path,
    p_media_size_bytes
  )
  returning * into v_msg;

  return v_msg;
end;
$$;

grant execute on function public.send_image_message(uuid, text, text, int) to authenticated;

-- ============================================================
-- #3  send_voice_message — atomic insert of kind='voice' message
-- ============================================================
create or replace function public.send_voice_message(
  p_conversation_id uuid,
  p_media_path text,
  p_media_mime text,
  p_media_size_bytes int,
  p_duration_ms int
)
returns public.messages
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  v_caller uuid := auth.uid();
  v_folders text[];
  v_msg_id uuid;
  v_msg public.messages;
begin
  if v_caller is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_conversation_id is null then
    raise exception 'conversation_id required' using errcode = '22023';
  end if;
  if p_media_path is null or length(p_media_path) = 0 then
    raise exception 'media_path required' using errcode = '22023';
  end if;
  if p_duration_ms is null or p_duration_ms <= 0 then
    raise exception 'duration_ms required' using errcode = '22023';
  end if;
  if p_duration_ms > 120000 then
    raise exception 'voice message exceeds 2 minute limit' using errcode = '22023';
  end if;
  if p_media_size_bytes is null or p_media_size_bytes <= 0 then
    raise exception 'media_size_bytes required' using errcode = '22023';
  end if;
  if p_media_size_bytes > 25 * 1024 * 1024 then
    raise exception 'voice message exceeds 25MB limit' using errcode = '22023';
  end if;

  -- Validate path layout: {conversationId}/{messageId}/{filename}
  v_folders := storage.foldername(p_media_path);
  if v_folders is null or array_length(v_folders, 1) <> 2 then
    raise exception 'invalid media_path layout' using errcode = '22023';
  end if;
  if v_folders[1] <> p_conversation_id::text then
    raise exception 'media_path conversation mismatch' using errcode = '22023';
  end if;

  begin
    v_msg_id := v_folders[2]::uuid;
  exception when others then
    raise exception 'media_path message_id segment must be a uuid' using errcode = '22023';
  end;

  -- Caller must be a participant in the conversation
  if not exists (
    select 1 from public.conversations c
    where c.id = p_conversation_id
      and (c.participant_a_id = v_caller or c.participant_b_id = v_caller)
  ) then
    raise exception 'not a participant' using errcode = '42501';
  end if;

  -- Caller must have uploaded the storage object
  if not exists (
    select 1 from storage.objects
    where bucket_id = 'chat-media'
      and name = p_media_path
      and owner = v_caller
  ) then
    raise exception 'media object not found or not owned by caller'
      using errcode = '42501';
  end if;

  insert into public.messages (
    id,
    conversation_id,
    sender_id,
    kind,
    media_path,
    media_size_bytes,
    media_duration_ms
  ) values (
    v_msg_id,
    p_conversation_id,
    v_caller,
    'voice'::public.message_kind,
    p_media_path,
    p_media_size_bytes,
    p_duration_ms
  )
  returning * into v_msg;

  return v_msg;
end;
$$;

grant execute on function public.send_voice_message(uuid, text, text, int, int) to authenticated;

-- ============================================================
-- Summary
-- ============================================================
-- * chat-media INSERT relaxed to participant-scoped (was: required pre-existing
--   message row owned by caller). Upload now precedes the message row.
-- * send_image_message(uuid, text, text, int) → public.messages
--   Validates path layout, conversation participation, storage ownership;
--   extracts message_id from path[2] and inserts kind='image' atomically.
-- * send_voice_message(uuid, text, text, int, int) → public.messages
--   Same pattern + duration; inserts kind='voice' (triggers transcription).
-- NOTE: Orphan storage objects are possible if the RPC errors after a
-- successful upload. Acceptable trade for atomic message rows; a cleanup
-- cron could sweep chat-media objects with no matching message row.
