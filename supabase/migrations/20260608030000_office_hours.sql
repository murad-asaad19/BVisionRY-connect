-- Office hours / availability slots.
--
-- A host (typically an investor / advisor / experienced founder) configures
-- weekly recurring availability windows (per-weekday start/end + IANA
-- timezone). The system materializes specific bookable `office_hours_slots`
-- rows for the next 14 days. Bookers pick a slot from the host's profile;
-- `book_slot` atomically claims it and spawns a pre-confirmed
-- `meeting_proposals` row so the existing ICS / push / post-meeting-review
-- pipeline takes over from there.
--
-- Design notes
-- ------------
-- 1. Settings are a single jsonb-of-windows column rather than a child table
--    because windows are small (typically 1-5 per host) and always edited as
--    a group. Validation of the jsonb shape lives in set_office_hours.
--
-- 2. Slots are materialized — we don't compute "next 14 days of openings"
--    on the fly because (a) it keeps the booking RPC atomic via SELECT FOR
--    UPDATE on a real row, and (b) it gives us a unique index to dedupe
--    re-materializations idempotently.
--
-- 3. Cancellation policy: > 24h away → slot reopens (status='open') so
--    someone else can grab it; ≤ 24h → marks cancelled (host wasted prep).
--    The underlying meeting_proposal is always cancelled.
--
-- 4. Booking creates a `meeting_proposals` row with state='confirmed'
--    directly (bypassing propose_meeting / confirm_meeting) because there's
--    no negotiation: the host has pre-committed to the time and the booker
--    is selecting from it. The two-party participant check on the
--    conversation still applies — we create the conversation if necessary
--    (canonical ordering preserved).

-- =============================================================================
-- (1) Tables.
-- =============================================================================
create table public.office_hours_settings (
  user_id                 uuid primary key references public.profiles(id) on delete cascade,
  enabled                 boolean not null default false,
  -- jsonb array of weekly windows. Each window has:
  -- { weekday: 0-6 (0=Sunday), start_minute: 0-1439, end_minute: 0-1439, timezone: text (IANA) }
  -- E.g. [{"weekday": 2, "start_minute": 840, "end_minute": 900, "timezone": "America/New_York"}]
  windows                 jsonb not null default '[]'::jsonb,
  slot_duration_minutes   int not null default 15,
  max_bookings_per_week   int not null default 5,
  buffer_minutes          int not null default 5,
  meeting_link_template   text,
  notes_template          text,
  updated_at              timestamptz not null default now(),
  constraint office_hours_slot_duration  check (slot_duration_minutes in (15, 30, 45, 60)),
  constraint office_hours_buffer         check (buffer_minutes between 0 and 60),
  constraint office_hours_max_bookings   check (max_bookings_per_week between 1 and 50),
  constraint office_hours_windows_shape  check (jsonb_typeof(windows) = 'array')
);

create table public.office_hours_slots (
  id                    uuid primary key default gen_random_uuid(),
  host_id               uuid not null references public.profiles(id) on delete cascade,
  starts_at             timestamptz not null,
  ends_at               timestamptz not null,
  status                text not null default 'open',
  booked_by             uuid references public.profiles(id) on delete set null,
  booked_at             timestamptz,
  meeting_proposal_id   uuid references public.meeting_proposals(id) on delete set null,
  topic                 text,
  constraint office_hours_slot_status  check (status in ('open', 'booked', 'cancelled')),
  constraint office_hours_slot_window  check (ends_at > starts_at)
);

create unique index office_hours_slots_unique_host_start
  on public.office_hours_slots (host_id, starts_at);
create index office_hours_slots_open_idx
  on public.office_hours_slots (host_id, starts_at)
  where status = 'open';
create index office_hours_slots_booker_idx
  on public.office_hours_slots (booked_by, starts_at desc)
  where status = 'booked';

create trigger office_hours_settings_set_updated_at
  before update on public.office_hours_settings
  for each row execute function extensions.moddatetime(updated_at);

-- =============================================================================
-- (2) RLS.
-- =============================================================================
alter table public.office_hours_settings enable row level security;
alter table public.office_hours_slots    enable row level security;

-- Anyone authenticated may read another user's settings (presence only).
-- Writes go through set_office_hours.
create policy office_hours_settings_read_all
  on public.office_hours_settings for select to authenticated
  using (true);

create policy office_hours_settings_no_direct_mutate
  on public.office_hours_settings for all to authenticated
  using (false) with check (false);

-- Slots: host always sees own; booker sees their own bookings; any
-- authenticated user can see OPEN slots (so the booking surface works).
create policy office_hours_slots_read
  on public.office_hours_slots for select to authenticated
  using (
    host_id   = auth.uid()
    or booked_by = auth.uid()
    or status    = 'open'
  );

create policy office_hours_slots_no_direct_mutate
  on public.office_hours_slots for all to authenticated
  using (false) with check (false);

-- =============================================================================
-- (3) Materialization helper (internal — never granted).
-- =============================================================================
-- Wipe future OPEN slots and regenerate from the host's windows. Idempotent
-- — the unique index on (host_id, starts_at) ensures repeat runs are no-ops
-- where a slot already exists. Booked / cancelled slots are never touched.
create or replace function public.materialize_office_hours_slots(p_host uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_settings      public.office_hours_settings;
  v_window        jsonb;
  v_day           int;
  v_weekday       int;
  v_start_minute  int;
  v_end_minute    int;
  v_tz            text;
  v_day_date      date;
  v_slot_start    timestamptz;
  v_slot_end      timestamptz;
  v_window_end    timestamptz;
  v_duration      interval;
  v_step          interval;
  v_floor         timestamptz := now() + interval '1 hour';
  v_horizon       timestamptz := now() + interval '14 days';
begin
  select * into v_settings from public.office_hours_settings where user_id = p_host;
  if not found then return; end if;
  if not v_settings.enabled then return; end if;
  if jsonb_array_length(v_settings.windows) = 0 then return; end if;

  v_duration := (v_settings.slot_duration_minutes || ' minutes')::interval;
  v_step     := ((v_settings.slot_duration_minutes + v_settings.buffer_minutes) || ' minutes')::interval;

  -- Wipe future OPEN slots (don't touch booked / cancelled).
  delete from public.office_hours_slots
    where host_id   = p_host
      and status    = 'open'
      and starts_at > now();

  -- For each window, walk the next 14 days.
  for v_window in select * from jsonb_array_elements(v_settings.windows) loop
    v_weekday      := (v_window->>'weekday')::int;
    v_start_minute := (v_window->>'start_minute')::int;
    v_end_minute   := (v_window->>'end_minute')::int;
    v_tz           := v_window->>'timezone';

    if v_weekday is null or v_start_minute is null or v_end_minute is null or v_tz is null then
      continue;
    end if;
    if v_end_minute <= v_start_minute then continue; end if;

    for v_day in 0..13 loop
      v_day_date := (current_date + v_day);
      -- dow (0=Sunday) computed in the host's timezone so windows land on
      -- the host's local weekday, not the server's.
      if extract(dow from ((v_day_date || ' 12:00')::timestamp at time zone v_tz)) <> v_weekday then
        continue;
      end if;

      -- Build the local start/end as wall clock then convert to UTC via the
      -- timezone. This is DST-correct: `at time zone` does the offset for us.
      v_slot_start := ((v_day_date || ' 00:00')::timestamp + (v_start_minute || ' minutes')::interval)
                      at time zone v_tz;
      v_window_end := ((v_day_date || ' 00:00')::timestamp + (v_end_minute   || ' minutes')::interval)
                      at time zone v_tz;

      while v_slot_start + v_duration <= v_window_end loop
        v_slot_end := v_slot_start + v_duration;
        if v_slot_start >= v_floor and v_slot_start <= v_horizon then
          insert into public.office_hours_slots (host_id, starts_at, ends_at)
          values (p_host, v_slot_start, v_slot_end)
          on conflict (host_id, starts_at) do nothing;
        end if;
        v_slot_start := v_slot_start + v_step;
      end loop;
    end loop;
  end loop;
end;
$$;

-- Internal — never granted.
revoke all on function public.materialize_office_hours_slots(uuid) from public, anon, authenticated;

-- =============================================================================
-- (4) set_office_hours — validates + upserts + materializes.
-- =============================================================================
create or replace function public.set_office_hours(
  p_enabled                 boolean,
  p_windows                 jsonb,
  p_slot_duration_minutes   int,
  p_max_bookings_per_week   int,
  p_buffer_minutes          int,
  p_meeting_link_template   text,
  p_notes_template          text
)
returns public.office_hours_settings
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user      uuid := auth.uid();
  v_settings  public.office_hours_settings;
  v_window    jsonb;
  v_weekday   int;
  v_start     int;
  v_end       int;
  v_tz        text;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  if p_windows is null or jsonb_typeof(p_windows) <> 'array' then
    raise exception 'windows must be a jsonb array' using errcode = '22023';
  end if;
  if p_slot_duration_minutes not in (15, 30, 45, 60) then
    raise exception 'slot_duration_minutes must be 15/30/45/60' using errcode = '22023';
  end if;
  if p_buffer_minutes < 0 or p_buffer_minutes > 60 then
    raise exception 'buffer_minutes must be between 0 and 60' using errcode = '22023';
  end if;
  if p_max_bookings_per_week < 1 or p_max_bookings_per_week > 50 then
    raise exception 'max_bookings_per_week must be between 1 and 50' using errcode = '22023';
  end if;

  for v_window in select * from jsonb_array_elements(p_windows) loop
    if jsonb_typeof(v_window) <> 'object' then
      raise exception 'each window must be a jsonb object' using errcode = '22023';
    end if;

    v_weekday := (v_window->>'weekday')::int;
    v_start   := (v_window->>'start_minute')::int;
    v_end     := (v_window->>'end_minute')::int;
    v_tz      := v_window->>'timezone';

    if v_weekday is null or v_weekday < 0 or v_weekday > 6 then
      raise exception 'window.weekday must be 0-6' using errcode = '22023';
    end if;
    if v_start is null or v_start < 0 or v_start > 1439 then
      raise exception 'window.start_minute must be 0-1439' using errcode = '22023';
    end if;
    if v_end is null or v_end < 0 or v_end > 1439 then
      raise exception 'window.end_minute must be 0-1439' using errcode = '22023';
    end if;
    if v_end <= v_start then
      raise exception 'window.end_minute must be greater than start_minute' using errcode = '22023';
    end if;
    if v_tz is null or not exists (select 1 from pg_timezone_names where name = v_tz) then
      raise exception 'window.timezone must be a valid IANA timezone name' using errcode = '22023';
    end if;
  end loop;

  insert into public.office_hours_settings (
    user_id, enabled, windows, slot_duration_minutes, max_bookings_per_week,
    buffer_minutes, meeting_link_template, notes_template
  ) values (
    v_user, p_enabled, p_windows, p_slot_duration_minutes, p_max_bookings_per_week,
    p_buffer_minutes, p_meeting_link_template, p_notes_template
  )
  on conflict (user_id) do update set
    enabled                = excluded.enabled,
    windows                = excluded.windows,
    slot_duration_minutes  = excluded.slot_duration_minutes,
    max_bookings_per_week  = excluded.max_bookings_per_week,
    buffer_minutes         = excluded.buffer_minutes,
    meeting_link_template  = excluded.meeting_link_template,
    notes_template         = excluded.notes_template
  returning * into v_settings;

  perform public.materialize_office_hours_slots(v_user);

  return v_settings;
end;
$$;

revoke all on function public.set_office_hours(boolean, jsonb, int, int, int, text, text) from public, anon;
grant execute on function public.set_office_hours(boolean, jsonb, int, int, int, text, text) to authenticated;

-- =============================================================================
-- (5) my_office_hours_settings — caller's own settings (or default-empty).
-- =============================================================================
create or replace function public.my_office_hours_settings()
returns public.office_hours_settings
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_row  public.office_hours_settings;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  select * into v_row from public.office_hours_settings where user_id = v_user;
  if not found then
    v_row.user_id               := v_user;
    v_row.enabled               := false;
    v_row.windows               := '[]'::jsonb;
    v_row.slot_duration_minutes := 15;
    v_row.max_bookings_per_week := 5;
    v_row.buffer_minutes        := 5;
    v_row.meeting_link_template := null;
    v_row.notes_template        := null;
    v_row.updated_at            := now();
  end if;
  return v_row;
end;
$$;

revoke all on function public.my_office_hours_settings() from public, anon;
grant execute on function public.my_office_hours_settings() to authenticated;

-- =============================================================================
-- (6) list_upcoming_slots — open slots in the next 14 days for a host.
-- =============================================================================
create or replace function public.list_upcoming_slots(p_host uuid)
returns table (
  id          uuid,
  starts_at   timestamptz,
  ends_at     timestamptz,
  host_settings_notes_template text
)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user     uuid := auth.uid();
  v_settings public.office_hours_settings;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  select * into v_settings from public.office_hours_settings where user_id = p_host;
  if not found or not v_settings.enabled then return; end if;

  -- Block-check in either direction.
  if exists (
    select 1 from public.blocks
     where (blocker_id = v_user and blocked_id = p_host)
        or (blocker_id = p_host and blocked_id = v_user)
  ) then
    return;
  end if;

  return query
    select
      s.id,
      s.starts_at,
      s.ends_at,
      v_settings.notes_template
    from public.office_hours_slots s
    where s.host_id   = p_host
      and s.status    = 'open'
      and s.starts_at > now()
      and s.starts_at < now() + interval '14 days'
    order by s.starts_at asc;
end;
$$;

revoke all on function public.list_upcoming_slots(uuid) from public, anon;
grant execute on function public.list_upcoming_slots(uuid) to authenticated;

-- =============================================================================
-- (7) book_slot — atomic claim + pre-confirmed meeting_proposal.
-- =============================================================================
create or replace function public.book_slot(p_slot_id uuid, p_topic text)
returns uuid
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user           uuid := auth.uid();
  v_slot           public.office_hours_slots;
  v_settings       public.office_hours_settings;
  v_conversation_id uuid;
  v_first          uuid;
  v_second         uuid;
  v_link           text;
  v_topic          text;
  v_week_start     timestamptz;
  v_existing_count int;
  v_proposal_id    uuid;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  v_topic := nullif(btrim(coalesce(p_topic, '')), '');
  if v_topic is null or char_length(v_topic) < 5 or char_length(v_topic) > 280 then
    raise exception 'topic must be 5-280 characters' using errcode = '22023';
  end if;

  -- Atomic claim: lock the slot row.
  select * into v_slot from public.office_hours_slots
    where id = p_slot_id
    for update;
  if not found then raise exception 'slot not found' using errcode = 'P0002'; end if;

  if v_slot.status <> 'open' then
    raise exception 'slot is not open' using errcode = '22023';
  end if;
  if v_slot.starts_at <= now() + interval '15 minutes' then
    raise exception 'slot is too close to start time' using errcode = '22023';
  end if;
  if v_slot.host_id = v_user then
    raise exception 'cannot book your own slot' using errcode = '22023';
  end if;

  -- Block check (both directions).
  if exists (
    select 1 from public.blocks
     where (blocker_id = v_user and blocked_id = v_slot.host_id)
        or (blocker_id = v_slot.host_id and blocked_id = v_user)
  ) then
    raise exception 'cannot book — host or viewer is blocked' using errcode = '42501';
  end if;

  -- Host settings (must still be enabled).
  select * into v_settings from public.office_hours_settings where user_id = v_slot.host_id;
  if not found or not v_settings.enabled then
    raise exception 'host is no longer accepting bookings' using errcode = '22023';
  end if;

  -- max_bookings_per_week — count active bookings by this viewer with this
  -- host whose slot falls within ISO-week (Monday 00:00 UTC bucket).
  v_week_start := date_trunc('week', now());
  select count(*)::int into v_existing_count
    from public.office_hours_slots s
    where s.host_id   = v_slot.host_id
      and s.booked_by = v_user
      and s.status    = 'booked'
      and s.starts_at >= v_week_start
      and s.starts_at <  v_week_start + interval '7 days';
  if v_existing_count >= v_settings.max_bookings_per_week then
    raise exception 'max bookings per week with this host reached' using errcode = '22023';
  end if;

  -- Find / create the canonical (a,b) conversation. participant_a_id <
  -- participant_b_id is enforced by the conversations check constraint.
  if v_user < v_slot.host_id then
    v_first  := v_user;
    v_second := v_slot.host_id;
  else
    v_first  := v_slot.host_id;
    v_second := v_user;
  end if;

  select id into v_conversation_id
    from public.conversations
    where participant_a_id = v_first and participant_b_id = v_second;
  if v_conversation_id is null then
    insert into public.conversations (participant_a_id, participant_b_id)
      values (v_first, v_second)
      returning id into v_conversation_id;
  end if;

  -- Resolve meeting URL via template ({slot_id} interpolation).
  v_link := v_settings.meeting_link_template;
  if v_link is not null then
    v_link := replace(v_link, '{slot_id}', v_slot.id::text);
    if v_link not like 'https://%' then v_link := null; end if;
  end if;

  -- Create a pre-confirmed meeting_proposals row. Direct INSERT bypasses
  -- propose_meeting / confirm_meeting because there's no negotiation: the
  -- host pre-committed via office_hours_settings, so the booker simply
  -- confirms a known slot. proposed_by_id = host so the booker's UI shows
  -- "you accepted" semantics, consistent with the rest of the meetings UX.
  insert into public.meeting_proposals (
    conversation_id, proposed_by_id, slots, confirmed_slot, duration_minutes,
    meeting_url, state, timezone
  ) values (
    v_conversation_id,
    v_slot.host_id,
    ARRAY[v_slot.starts_at]::timestamptz[],
    v_slot.starts_at,
    v_settings.slot_duration_minutes,
    v_link,
    'confirmed'::public.meeting_state,
    null
  ) returning id into v_proposal_id;

  -- Insert the chat-stream message bubble pointing at this proposal so the
  -- existing chat surface renders it consistently.
  insert into public.messages (conversation_id, sender_id, kind, meeting_proposal_id)
    values (v_conversation_id, v_user, 'meeting'::public.message_kind, v_proposal_id);

  -- Claim the slot.
  update public.office_hours_slots
    set status              = 'booked',
        booked_by           = v_user,
        booked_at           = now(),
        meeting_proposal_id = v_proposal_id,
        topic               = v_topic
    where id = p_slot_id;

  return v_proposal_id;
end;
$$;

revoke all on function public.book_slot(uuid, text) from public, anon;
grant execute on function public.book_slot(uuid, text) to authenticated;

-- =============================================================================
-- (8) cancel_booking — host OR booker can call.
--   > 24h away   → slot reopens (status='open'), proposal cancelled.
--   ≤ 24h away   → slot stays cancelled (status='cancelled'), proposal cancelled.
-- =============================================================================
create or replace function public.cancel_booking(p_slot_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user        uuid := auth.uid();
  v_slot        public.office_hours_slots;
  v_proposal_id uuid;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  select * into v_slot from public.office_hours_slots
    where id = p_slot_id
    for update;
  if not found then raise exception 'slot not found' using errcode = 'P0002'; end if;

  if v_user <> v_slot.host_id and v_user <> coalesce(v_slot.booked_by, '00000000-0000-0000-0000-000000000000'::uuid) then
    raise exception 'only host or booker can cancel' using errcode = '42501';
  end if;
  if v_slot.status <> 'booked' then
    raise exception 'slot is not currently booked' using errcode = '22023';
  end if;

  v_proposal_id := v_slot.meeting_proposal_id;

  if v_slot.starts_at > now() + interval '24 hours' then
    -- Reopen the slot for re-booking.
    update public.office_hours_slots
      set status              = 'open',
          booked_by           = null,
          booked_at           = null,
          meeting_proposal_id = null,
          topic               = null
      where id = p_slot_id;
  else
    -- Late cancel — don't reopen.
    update public.office_hours_slots
      set status              = 'cancelled',
          meeting_proposal_id = null
      where id = p_slot_id;
  end if;

  -- Cancel the underlying meeting_proposal regardless of timing. We update
  -- the row directly here (instead of routing through cancel_meeting) so
  -- that office-hours-spawned 'confirmed' proposals can transition to
  -- 'cancelled' — cancel_meeting only allows 'proposed' → 'cancelled'.
  if v_proposal_id is not null then
    update public.meeting_proposals
      set state = 'cancelled'::public.meeting_state
      where id = v_proposal_id
        and state <> 'cancelled'::public.meeting_state;
  end if;
end;
$$;

revoke all on function public.cancel_booking(uuid) from public, anon;
grant execute on function public.cancel_booking(uuid) to authenticated;

-- =============================================================================
-- (9) my_bookings — slots the caller has booked (with host profile fields).
-- =============================================================================
create or replace function public.my_bookings()
returns table (
  slot_id              uuid,
  host_id              uuid,
  host_handle          text,
  host_name            text,
  host_photo_url       text,
  starts_at            timestamptz,
  ends_at              timestamptz,
  topic                text,
  meeting_proposal_id  uuid
)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  return query
    select
      s.id            as slot_id,
      s.host_id,
      p.handle::text  as host_handle,
      p.name          as host_name,
      p.photo_url     as host_photo_url,
      s.starts_at,
      s.ends_at,
      s.topic,
      s.meeting_proposal_id
    from public.office_hours_slots s
    join public.profiles p on p.id = s.host_id
    where s.booked_by = v_user
      and s.status    = 'booked'
      and s.starts_at > now() - interval '1 hour'
    order by s.starts_at asc;
end;
$$;

revoke all on function public.my_bookings() from public, anon;
grant execute on function public.my_bookings() to authenticated;

-- =============================================================================
-- (10) Cron job — daily re-materialization of slots for every enabled host.
-- Re-runs the materializer so the rolling 14-day window stays fresh as the
-- days advance. Idempotent thanks to the unique index.
-- =============================================================================
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'office-hours-materialize-daily') then
    perform cron.schedule(
      'office-hours-materialize-daily',
      '15 2 * * *',
      $job$
        do $body$
        declare
          r record;
        begin
          for r in select user_id from public.office_hours_settings where enabled = true loop
            perform public.materialize_office_hours_slots(r.user_id);
          end loop;
        end
        $body$;
      $job$
    );
  end if;
end
$$;
