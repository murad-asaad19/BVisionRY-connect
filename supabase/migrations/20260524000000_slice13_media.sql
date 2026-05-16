-- Slice 13: media — buckets, RLS, message_kind extension

-- ============================================================
-- Storage buckets
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('chat-media', 'chat-media', false, 26214400, array['image/jpeg','image/png','image/webp','audio/mp4','audio/aac','audio/m4a','audio/webm'])
on conflict (id) do nothing;

-- Avatars: anyone can read; only owner can write under their {userid}/ folder
create policy "avatars-read" on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars-insert" on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars-update" on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars-delete" on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Chat media: only conversation participants can read/write under {conversationId}/...
create policy "chat-media-read" on storage.objects for select
  using (
    bucket_id = 'chat-media'
    and exists (
      select 1 from public.conversations c
      where c.id::text = (storage.foldername(name))[1]
        and (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
    )
  );

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
-- message_kind: add image + voice via drop-recreate (single-tx safe)
-- ============================================================

-- Remove dependents (constraint references the enum)
alter table public.messages drop constraint if exists messages_kind_payload;

-- Rewire column to text temporarily, drop type, recreate, rewire
alter table public.messages alter column kind drop default;
alter table public.messages alter column kind type text using kind::text;
drop type public.message_kind;
create type public.message_kind as enum ('text', 'meeting', 'image', 'voice');
alter table public.messages alter column kind type public.message_kind using kind::public.message_kind;
alter table public.messages alter column kind set default 'text'::public.message_kind;

-- Add media columns and relax body
alter table public.messages
  add column media_path text,
  add column media_duration_ms integer,
  add column media_size_bytes integer;

alter table public.messages alter column body drop not null;

alter table public.messages drop constraint if exists messages_body_len;
alter table public.messages add constraint messages_body_len
  check (body is null or char_length(body) between 1 and 4000);

alter table public.messages add constraint messages_kind_payload check (
  (kind = 'text'::public.message_kind
    and body is not null
    and meeting_proposal_id is null
    and media_path is null)
  or (kind = 'meeting'::public.message_kind
    and meeting_proposal_id is not null
    and body is null)
  or (kind = 'image'::public.message_kind
    and media_path is not null
    and meeting_proposal_id is null)
  or (kind = 'voice'::public.message_kind
    and media_path is not null
    and media_duration_ms is not null
    and meeting_proposal_id is null)
);

-- ============================================================
-- Update push notify_message_inserted to summarize media kinds
-- ============================================================
create or replace function public.notify_message_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_recipient uuid;
  v_conv public.conversations;
  v_body text;
  v_title text;
begin
  if new.sender_id is null then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := case
    when v_conv.participant_a_id = new.sender_id then v_conv.participant_b_id
    else v_conv.participant_a_id
  end;

  if new.kind = 'meeting'::public.message_kind then
    v_title := 'New meeting proposal';
    v_body  := 'Tap to view the proposed times.';
  elsif new.kind = 'image'::public.message_kind then
    v_title := 'New photo';
    v_body  := '📷 Photo';
  elsif new.kind = 'voice'::public.message_kind then
    v_title := 'New voice message';
    v_body  := '🎤 Voice message';
  else
    v_title := 'New message';
    v_body  := coalesce(left(new.body, 80), '');
  end if;

  perform public.dispatch_push(
    v_recipient,
    'messages',
    new.id,
    jsonb_build_object(
      'kind', case
        when new.kind = 'meeting'::public.message_kind then 'meeting_received'
        when new.kind = 'image'::public.message_kind then 'image_received'
        when new.kind = 'voice'::public.message_kind then 'voice_received'
        else 'message_received'
      end,
      'title', v_title,
      'body', v_body,
      'url', '/(app)/chats/' || new.conversation_id
    )
  );
  return new;
end; $$;
