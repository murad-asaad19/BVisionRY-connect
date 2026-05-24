-- Pass X-Supabase-Webhook-Secret on dispatch_push / dispatch_transcription so
-- the verify_jwt=false edge functions can authenticate the caller. Secret is
-- sourced from the cluster GUC app.webhook_shared_secret and must match the
-- WEBHOOK_SHARED_SECRET env var on the edge functions. Also stops writing
-- SQLERRM into messages.transcript on dispatch failure.

create or replace function public.dispatch_push(
  p_event_table text,
  p_event_id uuid,
  p_recipient_id uuid,
  p_payload jsonb
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
begin
  insert into public.push_log (event_table, event_id, recipient_id, payload)
  values (p_event_table, p_event_id, p_recipient_id, p_payload)
  on conflict (event_table, event_id, recipient_id) do nothing;

  select exists (
    select 1 from public.device_tokens
    where user_id = p_recipient_id and revoked_at is null
  ) into v_has_active_token;
  if not v_has_active_token then return; end if;

  begin
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'X-Supabase-Webhook-Secret', coalesce(v_secret, '')
      ),
      body := jsonb_build_object(
        'recipient_id', p_recipient_id,
        'event_table', p_event_table,
        'event_id', p_event_id,
        'payload', p_payload
      )
    );
  exception when others then
    update public.push_log
    set error = SQLERRM
    where event_table = p_event_table and event_id = p_event_id and recipient_id = p_recipient_id;
  end;
end;
$$;

create or replace function public.dispatch_transcription(p_message_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_url text := coalesce(
    current_setting('app.functions_base_url', true),
    'http://kong:8000'
  ) || '/functions/v1/transcribe-voice';
  v_secret text := current_setting('app.webhook_shared_secret', true);
begin
  update public.messages set transcript_status = 'pending'::public.transcript_status
  where id = p_message_id and transcript_status is null;
  begin
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'X-Supabase-Webhook-Secret', coalesce(v_secret, '')
      ),
      body := jsonb_build_object('message_id', p_message_id)
    );
  exception when others then
    update public.messages
    set transcript_status = 'failed'::public.transcript_status
    where id = p_message_id;
  end;
end;
$$;
