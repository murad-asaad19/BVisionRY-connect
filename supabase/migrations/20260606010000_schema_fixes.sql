-- Schema correctness fixes (column/index/constraint/FK/enum/non-trigger function rewrites).
-- Companion file 20260606030000_schema_fixes_triggers.sql rewrites trigger functions
-- that reference the new notification_kind enum values added here (Postgres requires
-- the ADD VALUE to commit before the value is usable inside another function body,
-- so the trigger rewrites are split into a second migration).

-- =============================================================================
-- #1 messages.sender_id FK: drop misleading SET NULL, switch to CASCADE.
-- Rationale: conversations cascade-delete on profile delete, taking messages
-- with them — the SET NULL on sender_id is unreachable. CASCADE matches the
-- de facto behaviour. (Default constraint name from slice5: messages_sender_id_fkey)
-- =============================================================================
alter table public.messages
  drop constraint if exists messages_sender_id_fkey;
alter table public.messages
  add constraint messages_sender_id_fkey
    foreign key (sender_id) references public.profiles(id) on delete cascade;

-- =============================================================================
-- #4 pg_trgm GIN indexes for search_discoverable_profiles ILIKE filters.
-- =============================================================================
create extension if not exists pg_trgm with schema extensions;

create index if not exists profiles_handle_trgm_idx
  on public.profiles using gin (handle extensions.gin_trgm_ops);
create index if not exists profiles_name_trgm_idx
  on public.profiles using gin (name extensions.gin_trgm_ops);

-- =============================================================================
-- #6 device_tokens.revoked_at + index supporting active-only lookups.
-- (#5 dispatch_push will filter on this column; rewritten below.)
-- =============================================================================
alter table public.device_tokens
  add column if not exists revoked_at timestamptz;

create index if not exists device_tokens_user_active_idx
  on public.device_tokens (user_id) where revoked_at is null;

-- =============================================================================
-- #8 New notification_kind values for specific meeting events.
-- These must be ADDed in a transaction that commits before any function body
-- references them at runtime — hence the trigger rewrites live in the next
-- migration file.
-- =============================================================================
alter type public.notification_kind add value if not exists 'meeting_proposal';
alter type public.notification_kind add value if not exists 'meeting_confirmed';

-- =============================================================================
-- #9 Partial index on messages.sender_id for lookups by sender (excluding
-- tombstoned NULL senders).
-- =============================================================================
create index if not exists messages_sender_idx
  on public.messages (sender_id) where sender_id is not null;

-- =============================================================================
-- #10 reports lookup index by target type + id + recency.
-- (Existing reports_target_idx is on (target_type, target_id) only — keep it,
-- new index is purposed for recent-first listings.)
-- =============================================================================
create index if not exists reports_target_created_idx
  on public.reports (target_type, target_id, created_at desc);

-- =============================================================================
-- #11 meeting_proposals.timezone IANA-name validation via CHECK.
-- Uses `now() at time zone <tz>` which raises 22023 on invalid zone names,
-- so a NOT VALID + VALIDATE pass enforces the check on all existing rows too.
-- =============================================================================
alter table public.meeting_proposals
  drop constraint if exists mp_timezone_valid;
alter table public.meeting_proposals
  add constraint mp_timezone_valid
    check (timezone is null or (now() at time zone timezone) is not null) not valid;
alter table public.meeting_proposals
  validate constraint mp_timezone_valid;

-- =============================================================================
-- #12 Drop redundant profiles.email column.
-- auth.users.email is the source of truth; profiles.email duplicates it.
-- Verified no mobile/Edge Function code reads profiles.email; only the slice1
-- handle_new_auth_user trigger writes to it, so rewrite the trigger first.
-- =============================================================================
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

alter table public.profiles
  drop column if exists email;

-- =============================================================================
-- #13 Replace handle lookups with citext-native equality (uses the unique index
-- on profiles.handle directly instead of lower(handle::text)).
-- Redefining functions originally created in earlier (non-editable) migrations
-- is in-scope here per the task.
-- =============================================================================
create or replace function public.lookup_email_by_handle(p_handle text)
returns text
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_email text;
begin
  if p_handle is null or trim(p_handle) = '' then
    return null;
  end if;
  select u.email::text
    into v_email
    from public.profiles p
    join auth.users u on u.id = p.id
   where p.handle = trim(p_handle)::extensions.citext;
  return v_email;
end;
$$;
grant execute on function public.lookup_email_by_handle(text) to anon, authenticated;

create or replace function public.get_public_profile(p_handle text)
returns table (
  id uuid,
  handle text,
  name text,
  photo_url text,
  headline text,
  bio text,
  primary_role public.role_kind,
  roles public.role_kind[],
  city text,
  country text,
  verified_github_username text
)
language plpgsql stable security definer set search_path = public, extensions
as $$
begin
  if p_handle is null or length(trim(p_handle)) = 0 then
    raise exception 'handle required' using errcode='22023';
  end if;
  return query
  select p.id, p.handle::text, p.name, p.photo_url, p.headline, p.bio,
         p.primary_role, p.roles, p.city, p.country,
         case when p.public_investor_page then p.verified_github_username else null end
  from public.profiles p
  where p.handle = trim(p_handle)::extensions.citext
    and p.onboarded = true
    and not p.private_mode;
end;
$$;
grant execute on function public.get_public_profile(text) to anon, authenticated;

-- =============================================================================
-- #14 messages.transcript_status → proper enum.
-- Edge function `transcribe-voice` writes 'ready' and 'unsupported' in addition
-- to 'pending' and 'failed', so the enum keeps those values to avoid breaking
-- the function (which this agent cannot edit). Deviation noted: task asked for
-- ('pending','ok','failed'); reality required ('pending','ready','failed',
-- 'unsupported'). 'ok' is intentionally omitted — no caller writes it.
-- =============================================================================
do $$
declare
  v_unknown text;
begin
  if not exists (select 1 from pg_type where typname = 'transcript_status'
                  and typnamespace = 'public'::regnamespace) then
    create type public.transcript_status as enum
      ('pending', 'ready', 'failed', 'unsupported');
  end if;

  -- Surface any unexpected legacy values before the cast attempts to convert them.
  select string_agg(distinct transcript_status, ', ')
    into v_unknown
    from public.messages
   where transcript_status is not null
     and transcript_status not in ('pending', 'ready', 'failed', 'unsupported');
  if v_unknown is not null then
    raise notice 'transcript_status values not in enum will be set to NULL: %', v_unknown;
    update public.messages
       set transcript_status = null
     where transcript_status is not null
       and transcript_status not in ('pending', 'ready', 'failed', 'unsupported');
  end if;
end $$;

alter table public.messages
  alter column transcript_status type public.transcript_status
  using transcript_status::public.transcript_status;

-- =============================================================================
-- #15 intros.note length CHECK now operates on btrim — prevents whitespace
-- padding bypassing the 80-400 minimum.
-- =============================================================================
alter table public.intros
  drop constraint if exists intros_note_len;
alter table public.intros
  add constraint intros_note_len
    check (char_length(btrim(note)) between 80 and 400);

-- =============================================================================
-- #5 dispatch_push: read base URL from GUC `app.functions_base_url`
-- (fallback to local Kong gateway for dev). Also filters out revoked tokens
-- (#6) by limiting the recipient lookup before the HTTP call.
--
-- To configure in production:
--   alter database <db> set app.functions_base_url = 'https://<project>.functions.supabase.co';
-- Per-session override is possible via set_config('app.functions_base_url', ...).
-- =============================================================================
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
  v_url text := coalesce(
    current_setting('app.functions_base_url', true),
    'http://kong:8000'
  ) || '/functions/v1/send-push';
  v_has_active_token boolean;
begin
  insert into public.push_log (event_table, event_id, recipient_id, payload)
  values (p_event_table, p_event_id, p_recipient_id, p_payload)
  on conflict (event_table, event_id, recipient_id) do nothing;

  -- Skip the HTTP call if the recipient has no live device tokens.
  select exists (
    select 1 from public.device_tokens
    where user_id = p_recipient_id and revoked_at is null
  ) into v_has_active_token;
  if not v_has_active_token then return; end if;

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

-- =============================================================================
-- #5 dispatch_transcription: same GUC pattern.
-- =============================================================================
create or replace function public.dispatch_transcription(p_message_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_url text := coalesce(
    current_setting('app.functions_base_url', true),
    'http://kong:8000'
  ) || '/functions/v1/transcribe-voice';
begin
  update public.messages set transcript_status = 'pending'::public.transcript_status
  where id = p_message_id and transcript_status is null;
  begin
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := jsonb_build_object('message_id', p_message_id)
    );
  exception when others then
    update public.messages
    set transcript_status = 'failed'::public.transcript_status,
        transcript = SQLERRM
    where id = p_message_id;
  end;
end;
$$;

-- =============================================================================
-- #7 mark_conversation_read: short-circuit when reader has opted out of
-- read receipts. Note: this also suppresses the reader's own unread count
-- in list_conversation_unread() (which reads from conversation_reads). The
-- task explicitly asks for the short-circuit; flagged for follow-up review.
-- =============================================================================
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_rr_enabled boolean;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  select read_receipts_enabled into v_rr_enabled
    from public.profiles where id = v_user;
  if not coalesce(v_rr_enabled, false) then
    return;
  end if;

  insert into public.conversation_reads (user_id, conversation_id, last_read_at)
  values (v_user, p_conversation_id, now())
  on conflict (user_id, conversation_id) do update set last_read_at = now();
end;
$$;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
