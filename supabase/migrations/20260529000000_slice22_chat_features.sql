-- Slice 22: chat features — read receipts, mute, typing (Realtime), edit + delete

-- ============================================================
-- conversation_reads: per-(user, conversation) last_read_at
-- ============================================================
create table public.conversation_reads (
  user_id uuid not null references public.profiles(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (user_id, conversation_id)
);

alter table public.conversation_reads enable row level security;
create policy conversation_reads_select_own on public.conversation_reads
  for select using (user_id = auth.uid());
create policy conversation_reads_upsert_own on public.conversation_reads
  for insert with check (user_id = auth.uid());
create policy conversation_reads_update_own on public.conversation_reads
  for update using (user_id = auth.uid());

-- ============================================================
-- conversation_mutes
-- ============================================================
create table public.conversation_mutes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  muted_at timestamptz not null default now(),
  primary key (user_id, conversation_id)
);

alter table public.conversation_mutes enable row level security;
create policy conversation_mutes_select_own on public.conversation_mutes
  for select using (user_id = auth.uid());
create policy conversation_mutes_insert_own on public.conversation_mutes
  for insert with check (user_id = auth.uid());
create policy conversation_mutes_delete_own on public.conversation_mutes
  for delete using (user_id = auth.uid());

-- ============================================================
-- Edit + delete columns on messages, relax kind_payload check
-- ============================================================
alter table public.messages
  add column edited_at timestamptz,
  add column deleted_at timestamptz;

-- Relax messages_kind_payload so deleted (tombstoned) rows can have null body/media_path
alter table public.messages drop constraint if exists messages_kind_payload;
alter table public.messages add constraint messages_kind_payload check (
  deleted_at is not null
  or (kind = 'text'::public.message_kind
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
-- RPCs: read receipts, mute, edit/delete, unread counts
-- ============================================================
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  insert into public.conversation_reads (user_id, conversation_id, last_read_at)
  values (v_user, p_conversation_id, now())
  on conflict (user_id, conversation_id) do update set last_read_at = now();
end;
$$;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

create or replace function public.mute_conversation(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  insert into public.conversation_mutes (user_id, conversation_id)
  values (v_user, p_conversation_id)
  on conflict do nothing;
end;
$$;
grant execute on function public.mute_conversation(uuid) to authenticated;

create or replace function public.unmute_conversation(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  delete from public.conversation_mutes where user_id = v_user and conversation_id = p_conversation_id;
end;
$$;
grant execute on function public.unmute_conversation(uuid) to authenticated;

create or replace function public.edit_message(p_id uuid, p_body text)
returns public.messages
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_msg public.messages;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  select * into v_msg from public.messages where id = p_id;
  if not found then raise exception 'message not found' using errcode='P0002'; end if;
  if v_msg.sender_id is distinct from v_user then
    raise exception 'only the sender can edit' using errcode='42501';
  end if;
  if v_msg.kind <> 'text'::public.message_kind then
    raise exception 'only text messages can be edited' using errcode='22023';
  end if;
  if v_msg.created_at < now() - interval '15 minutes' then
    raise exception 'edit window expired' using errcode='22023';
  end if;
  if v_msg.deleted_at is not null then
    raise exception 'cannot edit deleted message' using errcode='22023';
  end if;
  if char_length(p_body) < 1 or char_length(p_body) > 4000 then
    raise exception 'body must be 1-4000 chars' using errcode='22023';
  end if;
  update public.messages
  set body = p_body, edited_at = now()
  where id = p_id
  returning * into v_msg;
  return v_msg;
end;
$$;
grant execute on function public.edit_message(uuid, text) to authenticated;

create or replace function public.delete_message(p_id uuid)
returns public.messages
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_msg public.messages;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  select * into v_msg from public.messages where id = p_id;
  if not found then raise exception 'message not found' using errcode='P0002'; end if;
  if v_msg.sender_id is distinct from v_user then
    raise exception 'only the sender can delete' using errcode='42501';
  end if;
  update public.messages
  set deleted_at = now(),
      body = null,
      media_path = null
  where id = p_id
  returning * into v_msg;
  return v_msg;
end;
$$;
grant execute on function public.delete_message(uuid) to authenticated;

create or replace function public.list_conversation_unread()
returns table (conversation_id uuid, unread_count integer)
language sql stable security definer set search_path = public
as $$
  select c.id as conversation_id,
         (select count(*)::integer from public.messages m
          where m.conversation_id = c.id
            and m.sender_id is not null
            and m.sender_id <> auth.uid()
            and m.deleted_at is null
            and m.created_at > coalesce(
              (select last_read_at from public.conversation_reads
               where user_id = auth.uid() and conversation_id = c.id),
              '1970-01-01'::timestamptz
            )
         ) as unread_count
  from public.conversations c
  where auth.uid() in (c.participant_a_id, c.participant_b_id);
$$;
grant execute on function public.list_conversation_unread() to authenticated;

-- ============================================================
-- Update notify_message_inserted to respect mute
-- ============================================================
create or replace function public.notify_message_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_recipient uuid;
  v_conv public.conversations;
  v_body text;
  v_title text;
  v_pref boolean;
  v_muted boolean;
begin
  if new.sender_id is null then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := case
    when v_conv.participant_a_id = new.sender_id then v_conv.participant_b_id
    else v_conv.participant_a_id
  end;

  -- Skip notification if the recipient muted this conversation
  select exists(
    select 1 from public.conversation_mutes
    where user_id = v_recipient and conversation_id = new.conversation_id
  ) into v_muted;
  if v_muted then return new; end if;

  if new.kind = 'meeting'::public.message_kind then
    select notify_meeting into v_pref from public.profiles where id = v_recipient;
    v_title := 'New meeting proposal'; v_body := 'Tap to view the proposed times.';
  else
    select notify_message into v_pref from public.profiles where id = v_recipient;
    if new.kind = 'image'::public.message_kind then
      v_title := 'New photo'; v_body := '📷 Photo';
    elsif new.kind = 'voice'::public.message_kind then
      v_title := 'New voice message'; v_body := '🎤 Voice message';
    else
      v_title := 'New message'; v_body := coalesce(left(new.body, 80), '');
    end if;
  end if;

  if coalesce(v_pref, true) then
    perform public.dispatch_push(
      v_recipient, 'messages', new.id,
      jsonb_build_object(
        'kind', case
          when new.kind = 'meeting'::public.message_kind then 'meeting_received'
          when new.kind = 'image'::public.message_kind then 'image_received'
          when new.kind = 'voice'::public.message_kind then 'voice_received'
          else 'message_received'
        end,
        'title', v_title, 'body', v_body,
        'url','/(app)/chats/' || new.conversation_id
      )
    );
  end if;
  return new;
end; $$;
