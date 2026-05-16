-- Slice 16: settings expansions — notification prefs + data export RPC
-- Updates the three notify_* trigger functions to gate on recipient preference.

alter table public.profiles
  add column notify_intro    boolean not null default true,
  add column notify_message  boolean not null default true,
  add column notify_meeting  boolean not null default true;

-- Update trigger functions to respect prefs
create or replace function public.notify_intro_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_pref boolean;
begin
  if new.state = 'delivered' and new.recipient_id is not null then
    select notify_intro into v_pref from public.profiles where id = new.recipient_id;
    if coalesce(v_pref, true) then
      perform public.dispatch_push(
        new.recipient_id, 'intros', new.id,
        jsonb_build_object(
          'kind','intro_received','title','New intro','body','You have a new intro to review.',
          'url','/(app)/intros/' || new.id
        )
      );
    end if;
  end if;
  return new;
end; $$;

create or replace function public.notify_message_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_recipient uuid;
  v_conv public.conversations;
  v_body text;
  v_title text;
  v_pref boolean;
begin
  if new.sender_id is null then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := case
    when v_conv.participant_a_id = new.sender_id then v_conv.participant_b_id
    else v_conv.participant_a_id
  end;

  if new.kind = 'meeting'::public.message_kind then
    select notify_meeting into v_pref from public.profiles where id = v_recipient;
    v_title := 'New meeting proposal'; v_body := 'Tap to view the proposed times.';
  else
    select notify_message into v_pref from public.profiles where id = v_recipient;
    if new.kind = 'image'::public.message_kind then
      v_title := 'New photo'; v_body := 'Photo';
    elsif new.kind = 'voice'::public.message_kind then
      v_title := 'New voice message'; v_body := 'Voice message';
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

create or replace function public.notify_meeting_confirmed()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_conv public.conversations;
  v_recipient uuid;
  v_pref boolean;
begin
  if old.state = new.state then return new; end if;
  if new.state <> 'confirmed'::public.meeting_state then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := new.proposed_by_id;
  if v_recipient is null then return new; end if;
  select notify_meeting into v_pref from public.profiles where id = v_recipient;
  if coalesce(v_pref, true) then
    perform public.dispatch_push(
      v_recipient, 'meeting_proposals', new.id,
      jsonb_build_object(
        'kind','meeting_confirmed','title','Meeting confirmed',
        'body','Your meeting has been confirmed.',
        'url','/(app)/chats/' || new.conversation_id
      )
    );
  end if;
  return new;
end; $$;

-- Data export RPC
create or replace function public.export_my_data()
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  select jsonb_build_object(
    'profile', to_jsonb((select p from public.profiles p where p.id = v_user)),
    'intros_sent', coalesce((select jsonb_agg(to_jsonb(i)) from public.intros i where i.sender_id = v_user), '[]'::jsonb),
    'intros_received', coalesce((select jsonb_agg(to_jsonb(i)) from public.intros i where i.recipient_id = v_user), '[]'::jsonb),
    'conversations', coalesce((select jsonb_agg(to_jsonb(c)) from public.conversations c where c.participant_a_id = v_user or c.participant_b_id = v_user), '[]'::jsonb),
    'messages_sent', coalesce((select jsonb_agg(to_jsonb(m)) from public.messages m where m.sender_id = v_user), '[]'::jsonb),
    'meeting_proposals', coalesce((select jsonb_agg(to_jsonb(mp)) from public.meeting_proposals mp where mp.proposed_by_id = v_user), '[]'::jsonb),
    'blocks', coalesce((select jsonb_agg(to_jsonb(b)) from public.blocks b where b.blocker_id = v_user), '[]'::jsonb),
    'reports_filed', coalesce((select jsonb_agg(to_jsonb(r)) from public.reports r where r.reporter_id = v_user), '[]'::jsonb),
    'exported_at', now()
  ) into v_result;

  return v_result;
end;
$$;
grant execute on function public.export_my_data() to authenticated;
