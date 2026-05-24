-- Wave 5: dispatch_push payload refactor.
--
-- Goals
-- -----
--  1. Drop the orphaned (text, uuid, uuid, jsonb) overload accidentally created
--     in 20260606050000_dispatch_webhook_secret.sql. Triggers still call the
--     canonical (uuid, text, uuid, jsonb) signature, so the misnamed overload
--     just sits there as a footgun.
--
--  2. Recreate the canonical dispatch_push with three new defaulted parameters
--     so callers can attach a structured `data` payload alongside the legacy
--     `payload` (which carries the localized title/body/url for the dev stub
--     and any FCM clients that don't yet localize on-device):
--
--       p_kind            text   default null    -- e.g. 'intro_received'
--       p_entity_id       uuid   default null    -- the row id that triggered it
--       p_conversation_id uuid   default null    -- when the route needs it
--
--     The HTTP body sent to send-push now also carries:
--
--       data: { kind, entity_id, conversation_id }
--
--     send-push forwards these into the FCM `message.data` map so clients can
--     route deterministically and localize from i18n keys instead of parsing
--     the server-generated body string.
--
--  3. Rewrite notify_intro_inserted, notify_message_inserted, and
--     notify_meeting_confirmed to pass the new parameters. These are the latest
--     definitions (last touched in 20260606030000_schema_fixes_triggers.sql);
--     re-defining them here preserves all their existing behaviour (preference
--     gating via should_notify, conversation_mutes, the meeting_proposal /
--     meeting_confirmed split) and only adds the structured-data params.

-- =============================================================================
-- 1. Drop the broken overload from 20260606050000.
-- =============================================================================
drop function if exists public.dispatch_push(text, uuid, uuid, jsonb);

-- =============================================================================
-- 2. Canonical dispatch_push with structured-data params.
-- =============================================================================
create or replace function public.dispatch_push(
  p_recipient_id   uuid,
  p_event_table    text,
  p_event_id       uuid,
  p_payload        jsonb,
  p_kind           text default null,
  p_entity_id      uuid default null,
  p_conversation_id uuid default null
)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_url text := coalesce(
    current_setting('app.functions_base_url', true),
    'http://kong:8000'
  ) || '/functions/v1/send-push';
  v_secret text := current_setting('app.webhook_shared_secret', true);
  v_has_active_token boolean;
  v_data jsonb;
begin
  -- Persist the dispatch attempt up-front so send-push can validate the tuple
  -- via push_log (replay/spam protection — see send-push push_log binding).
  insert into public.push_log (event_table, event_id, recipient_id, payload)
  values (p_event_table, p_event_id, p_recipient_id, p_payload)
  on conflict (event_table, event_id, recipient_id) do nothing;

  -- Skip the HTTP call if the recipient has no live device tokens.
  select exists (
    select 1 from public.device_tokens
    where user_id = p_recipient_id and revoked_at is null
  ) into v_has_active_token;
  if not v_has_active_token then return; end if;

  -- Build the structured data payload only when the caller supplied any of
  -- the new params, so existing callers that pass nothing are unchanged.
  if p_kind is not null or p_entity_id is not null or p_conversation_id is not null then
    v_data := jsonb_strip_nulls(jsonb_build_object(
      'kind',            p_kind,
      'entity_id',       p_entity_id,
      'conversation_id', p_conversation_id
    ));
  end if;

  begin
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'X-Supabase-Webhook-Secret', coalesce(v_secret, '')
      ),
      body := jsonb_build_object(
        'recipient_id', p_recipient_id,
        'event_table',  p_event_table,
        'event_id',     p_event_id,
        'payload',      p_payload,
        'data',         v_data  -- null when no structured fields were supplied
      )
    );
  exception when others then
    update public.push_log
    set error = SQLERRM
    where event_table = p_event_table
      and event_id = p_event_id
      and recipient_id = p_recipient_id;
  end;
end;
$$;

-- =============================================================================
-- 3. Trigger function rewrites — now pass p_kind / p_entity_id / p_conversation_id.
-- All behaviour preserved from 20260606030000_schema_fixes_triggers.sql; only
-- the dispatch_push argument lists change.
-- =============================================================================

-- notify_intro_inserted ------------------------------------------------------
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
        new.recipient_id,
        'intros',
        new.id,
        jsonb_build_object(
          'kind',  'intro_received',
          'title', 'New intro',
          'body',  'You have a new intro to review.',
          'url',   '/(app)/intros/' || new.id
        ),
        p_kind            => 'intro_received',
        p_entity_id       => new.id,
        p_conversation_id => new.conversation_id
      );
    end if;
  end if;
  return new;
end;
$$;

-- notify_message_inserted ----------------------------------------------------
-- Honours conversation_mutes AND notification_preferences. Routes the meeting
-- message path through the new 'meeting_proposal' kind.
create or replace function public.notify_message_inserted()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_recipient uuid;
  v_conv public.conversations;
  v_body  text;
  v_title text;
  v_kind  public.notification_kind;
  v_data_kind text;
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
    v_kind      := 'meeting_proposal'::public.notification_kind;
    v_data_kind := 'meeting_proposal';
    v_title     := 'New meeting proposal';
    v_body      := 'Tap to view the proposed times.';
  elsif new.kind = 'image'::public.message_kind then
    v_kind      := 'message_received'::public.notification_kind;
    v_data_kind := 'image_received';
    v_title     := 'New photo';
    v_body      := 'Photo';
  elsif new.kind = 'voice'::public.message_kind then
    v_kind      := 'voice_received'::public.notification_kind;
    v_data_kind := 'voice_received';
    v_title     := 'New voice message';
    v_body      := 'Voice message';
  else
    v_kind      := 'message_received'::public.notification_kind;
    v_data_kind := 'message_received';
    v_title     := 'New message';
    v_body      := coalesce(left(new.body, 80), '');
  end if;

  if public.should_notify(v_recipient, v_kind, 'push'::public.notification_channel) then
    perform public.dispatch_push(
      v_recipient,
      'messages',
      new.id,
      jsonb_build_object(
        'kind',  v_data_kind,
        'title', v_title,
        'body',  v_body,
        'url',   '/(app)/chats/' || new.conversation_id
      ),
      p_kind            => v_data_kind,
      p_entity_id       => new.id,
      p_conversation_id => new.conversation_id
    );
  end if;
  return new;
end;
$$;

-- notify_meeting_confirmed ---------------------------------------------------
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
      v_recipient,
      'meeting_proposals',
      new.id,
      jsonb_build_object(
        'kind',  'meeting_confirmed',
        'title', 'Meeting confirmed',
        'body',  'Your meeting has been confirmed.',
        'url',   '/(app)/chats/' || new.conversation_id
      ),
      p_kind            => 'meeting_confirmed',
      p_entity_id       => new.id,
      p_conversation_id => new.conversation_id
    );
  end if;
  return new;
end;
$$;
