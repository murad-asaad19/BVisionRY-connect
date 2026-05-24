-- Schema-fix triggers (split from 20260606010000_schema_fixes.sql).
--
-- This file rewrites the notify_* trigger functions to:
--   #3  Source per-user notification preferences from `notification_preferences`
--       via `should_notify(recipient, kind, 'push')` instead of the legacy
--       `profiles.notify_intro/message/meeting` boolean columns.
--   #8  Use the new specific notification_kind values 'meeting_proposal' and
--       'meeting_confirmed' instead of the catch-all 'meeting_reminder'.
--
-- The legacy `profiles.notify_intro/message/meeting` columns are NOT dropped:
-- mobile/src/features/settings/services/settings.service.ts still writes them
-- via supabase.from('profiles').update({notify_intro, ...}). The columns are
-- harmless once the triggers stop reading them, but the drop must wait until
-- the mobile UI is migrated to write to `notification_preferences` instead.
-- Flagged for the next reviewer.

-- =============================================================================
-- notify_intro_inserted
-- =============================================================================
create or replace function public.notify_intro_inserted()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.state = 'delivered' and new.recipient_id is not null then
    if public.should_notify(
         new.recipient_id,
         'intro_received'::public.notification_kind,
         'push'::public.notification_channel
       ) then
      perform public.dispatch_push(
        new.recipient_id, 'intros', new.id,
        jsonb_build_object(
          'kind', 'intro_received',
          'title', 'New intro',
          'body', 'You have a new intro to review.',
          'url', '/(app)/intros/' || new.id
        )
      );
    end if;
  end if;
  return new;
end;
$$;

-- =============================================================================
-- notify_message_inserted
-- Honours conversation_mutes AND notification_preferences. Routes the meeting
-- message path through the new 'meeting_proposal' kind.
-- =============================================================================
create or replace function public.notify_message_inserted()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_recipient uuid;
  v_conv public.conversations;
  v_body  text;
  v_title text;
  v_kind  public.notification_kind;
  v_muted boolean;
begin
  if new.sender_id is null then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;

  v_recipient := case
    when v_conv.participant_a_id = new.sender_id then v_conv.participant_b_id
    else v_conv.participant_a_id
  end;

  -- Conversation-level mute trumps notification prefs.
  select exists (
    select 1 from public.conversation_mutes
    where user_id = v_recipient and conversation_id = new.conversation_id
  ) into v_muted;
  if v_muted then return new; end if;

  if new.kind = 'meeting'::public.message_kind then
    v_kind  := 'meeting_proposal'::public.notification_kind;
    v_title := 'New meeting proposal';
    v_body  := 'Tap to view the proposed times.';
  elsif new.kind = 'image'::public.message_kind then
    v_kind  := 'message_received'::public.notification_kind;
    v_title := 'New photo';
    v_body  := 'Photo';
  elsif new.kind = 'voice'::public.message_kind then
    v_kind  := 'voice_received'::public.notification_kind;
    v_title := 'New voice message';
    v_body  := 'Voice message';
  else
    v_kind  := 'message_received'::public.notification_kind;
    v_title := 'New message';
    v_body  := coalesce(left(new.body, 80), '');
  end if;

  if public.should_notify(v_recipient, v_kind, 'push'::public.notification_channel) then
    perform public.dispatch_push(
      v_recipient, 'messages', new.id,
      jsonb_build_object(
        'kind', case
          when new.kind = 'meeting'::public.message_kind then 'meeting_received'
          when new.kind = 'image'::public.message_kind   then 'image_received'
          when new.kind = 'voice'::public.message_kind   then 'voice_received'
          else 'message_received'
        end,
        'title', v_title,
        'body',  v_body,
        'url',   '/(app)/chats/' || new.conversation_id
      )
    );
  end if;
  return new;
end;
$$;

-- =============================================================================
-- notify_meeting_confirmed: fires the new 'meeting_confirmed' notification kind.
-- =============================================================================
create or replace function public.notify_meeting_confirmed()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_conv      public.conversations;
  v_recipient uuid;
begin
  if old.state = new.state then return new; end if;
  if new.state <> 'confirmed'::public.meeting_state then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := new.proposed_by_id;
  if v_recipient is null then return new; end if;

  if public.should_notify(
       v_recipient,
       'meeting_confirmed'::public.notification_kind,
       'push'::public.notification_channel
     ) then
    perform public.dispatch_push(
      v_recipient, 'meeting_proposals', new.id,
      jsonb_build_object(
        'kind',  'meeting_confirmed',
        'title', 'Meeting confirmed',
        'body',  'Your meeting has been confirmed.',
        'url',   '/(app)/chats/' || new.conversation_id
      )
    );
  end if;
  return new;
end;
$$;
