-- Slice 8: push pipeline — device_tokens + push_log + triggers + dispatch_push helper

create extension if not exists pg_net with schema extensions;

create type public.device_platform as enum ('ios', 'android', 'web');

create table public.device_tokens (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  token         text not null,
  platform      public.device_platform not null,
  last_seen_at  timestamptz not null default now(),
  created_at    timestamptz not null default now(),
  unique (user_id, token)
);

create index device_tokens_user_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

create policy device_tokens_select_own on public.device_tokens
  for select using (user_id = auth.uid());

create table public.push_log (
  id            uuid primary key default gen_random_uuid(),
  event_table   text not null,
  event_id      uuid not null,
  recipient_id  uuid not null references public.profiles(id) on delete cascade,
  payload       jsonb not null,
  delivered     boolean not null default false,
  error         text,
  created_at    timestamptz not null default now(),
  unique (event_table, event_id, recipient_id)
);

create index push_log_recipient_idx on public.push_log (recipient_id, created_at desc);

alter table public.push_log enable row level security;

create policy push_log_select_own on public.push_log
  for select using (recipient_id = auth.uid());

create or replace function public.register_device_token(p_token text, p_platform public.device_platform)
returns public.device_tokens
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row public.device_tokens;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if p_token is null or length(p_token) < 16 then
    raise exception 'invalid token' using errcode='22023';
  end if;

  insert into public.device_tokens (user_id, token, platform)
  values (v_user, p_token, p_platform)
  on conflict (user_id, token) do update
    set last_seen_at = now(),
        platform = excluded.platform
  returning * into v_row;

  return v_row;
end;
$$;
grant execute on function public.register_device_token(text, public.device_platform) to authenticated;

-- dispatch_push: write to push_log (idempotent) + best-effort HTTP call to edge function
create or replace function public.dispatch_push(
  p_recipient_id uuid,
  p_event_table  text,
  p_event_id     uuid,
  p_payload      jsonb
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url text := 'http://kong:8000/functions/v1/send-push';
begin
  insert into public.push_log (event_table, event_id, recipient_id, payload)
  values (p_event_table, p_event_id, p_recipient_id, p_payload)
  on conflict (event_table, event_id, recipient_id) do nothing;

  begin
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := jsonb_build_object(
        'recipient_id', p_recipient_id,
        'event_table', p_event_table,
        'event_id', p_event_id,
        'payload', p_payload
      )
    );
  exception
    when others then
      update public.push_log
      set error = SQLERRM
      where event_table = p_event_table and event_id = p_event_id and recipient_id = p_recipient_id;
  end;
end;
$$;

-- Triggers

create or replace function public.notify_intro_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.state = 'delivered' and new.recipient_id is not null then
    perform public.dispatch_push(
      new.recipient_id,
      'intros',
      new.id,
      jsonb_build_object(
        'kind', 'intro_received',
        'title', 'New intro',
        'body', 'You have a new intro to review.',
        'url', '/(app)/intros/' || new.id
      )
    );
  end if;
  return new;
end; $$;

create trigger intros_push_on_insert
  after insert on public.intros
  for each row execute function public.notify_intro_inserted();

create or replace function public.notify_message_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_recipient uuid;
  v_conv public.conversations;
begin
  if new.sender_id is null then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := case
    when v_conv.participant_a_id = new.sender_id then v_conv.participant_b_id
    else v_conv.participant_a_id
  end;
  perform public.dispatch_push(
    v_recipient,
    'messages',
    new.id,
    jsonb_build_object(
      'kind', case when new.kind = 'meeting' then 'meeting_received' else 'message_received' end,
      'title', case when new.kind = 'meeting' then 'New meeting proposal' else 'New message' end,
      'body', coalesce(left(new.body, 80), ''),
      'url', '/(app)/chats/' || new.conversation_id
    )
  );
  return new;
end; $$;

create trigger messages_push_on_insert
  after insert on public.messages
  for each row execute function public.notify_message_inserted();

create or replace function public.notify_meeting_confirmed()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_conv public.conversations;
  v_recipient uuid;
begin
  if old.state = new.state then return new; end if;
  if new.state <> 'confirmed'::public.meeting_state then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := new.proposed_by_id;
  if v_recipient is null then return new; end if;

  perform public.dispatch_push(
    v_recipient,
    'meeting_proposals',
    new.id,
    jsonb_build_object(
      'kind', 'meeting_confirmed',
      'title', 'Meeting confirmed',
      'body', 'Your meeting has been confirmed.',
      'url', '/(app)/chats/' || new.conversation_id
    )
  );
  return new;
end; $$;

create trigger meeting_proposals_push_on_confirm
  after update on public.meeting_proposals
  for each row execute function public.notify_meeting_confirmed();
