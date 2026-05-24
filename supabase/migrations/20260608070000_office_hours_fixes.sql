-- Office-hours post-review fixes.
--
-- Findings addressed
-- ------------------
-- #5 (silent booking): `book_slot` inserts a `meeting_proposals` row directly
--    in state='confirmed'. The canonical "Meeting confirmed" push is wired
--    to `notify_meeting_confirmed`, which is an AFTER UPDATE trigger — so an
--    INSERT born confirmed never fires it. The host therefore got *only* the
--    chat-bubble side push ("New meeting proposal — Tap to view the proposed
--    times.") from `notify_message_inserted`, with copy that's wrong for an
--    already-confirmed meeting.
--
--    Fix:
--      a) `book_slot` now explicitly calls `dispatch_push` with the
--         `meeting_confirmed` payload after the meeting_proposals row is
--         inserted, using the same shape `notify_meeting_confirmed` would
--         have used. Idempotency is preserved by the existing push_log
--         unique (event_table, event_id, recipient_id) constraint.
--      b) `notify_message_inserted` now detects the office-hours-booking
--         shape: a 'meeting'-kind message whose linked meeting_proposals
--         row is ALREADY in state='confirmed' at insert time. That can
--         only happen for pre-confirmed office-hours bookings — the normal
--         meeting flow inserts the chat bubble while the proposal is still
--         'proposed' and only later transitions to 'confirmed' via
--         confirm_meeting. In that case we skip the proposal-kind push
--         entirely (the meeting_confirmed dispatch from book_slot covers
--         the host's notification). The chat bubble itself stays — the chat
--         surface still renders the meeting card for both participants.
--
-- #13 (TZ-dependent weekly cap): the weekly-cap bucket used
--    `date_trunc('week', now())`. `date_trunc` operates in the SESSION
--    timezone (whatever the `TimeZone` GUC is set to). Supabase defaults
--    to UTC but that is not guaranteed — if a connection ever runs with
--    a non-UTC GUC the bucket boundary drifts, opening edge cases right
--    around Sunday→Monday in either direction. The fix is to do the trunc
--    against `(now() at time zone 'UTC')` so the week boundary is always
--    Monday 00:00 UTC. Both the bucket start and the upper bound use the
--    same expression.
--
-- #2-companion (materialize_office_hours_slots weekday computation):
--    The original used `extract(dow from ((v_day_date || ' 12:00')::timestamp
--    at time zone v_tz))`. Two issues:
--      (i)  `v_day_date := current_date + v_day` — `current_date` is in the
--           SESSION timezone, so the iteration walks UTC calendar days for
--           a UTC Supabase but is technically GUC-dependent.
--      (ii) `extract(dow from <timestamptz>)` extracts the day-of-week in
--           the SESSION timezone, NOT in `v_tz`. So for hosts in large-offset
--           zones (Pacific/Apia +14, Pacific/Kiritimati +14, Pacific/Marquesas
--           -09:30) the dow computed for a "host's local Wednesday at 12:00"
--           wall-clock can come out as Tuesday in UTC — and the loop iterates
--           through dates that never actually match, silently producing zero
--           slots.
--
--    Fix: drive the loop off `(now() at time zone v_tz)::date` (the host's
--    actual local "today"), iterate 0..13 host-local days forward, and
--    compute dow on the wall-clock TIMESTAMP (no `at time zone` indirection),
--    which is the host-local weekday by construction.

-- =============================================================================
-- 1. notify_message_inserted — suppress the proposal-kind push for
--    pre-confirmed (office-hours) bookings. Everything else is preserved
--    verbatim from 20260606150000_dispatch_push_payload.sql.
-- =============================================================================
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
  v_proposal_state public.meeting_state;
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

  -- Office-hours bookings insert a 'meeting'-kind chat bubble pointing at a
  -- meeting_proposals row that is ALREADY in state='confirmed'. The booking
  -- flow (`book_slot`) emits its own canonical meeting_confirmed push, so we
  -- must not also send the "New meeting proposal — tap to view the proposed
  -- times" push (wrong copy + double notification). Detect that case here.
  if new.kind = 'meeting'::public.message_kind
     and new.meeting_proposal_id is not null
  then
    select state into v_proposal_state
      from public.meeting_proposals
      where id = new.meeting_proposal_id;
    if v_proposal_state = 'confirmed'::public.meeting_state then
      return new;
    end if;
  end if;

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

-- =============================================================================
-- 2. materialize_office_hours_slots — host-local-calendar iteration + dow.
-- =============================================================================
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
  v_local_today   date;
  v_local_date    date;
  v_local_wall    timestamp;
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

  -- For each window, walk the next 14 days of the HOST'S local calendar.
  for v_window in select * from jsonb_array_elements(v_settings.windows) loop
    v_weekday      := (v_window->>'weekday')::int;
    v_start_minute := (v_window->>'start_minute')::int;
    v_end_minute   := (v_window->>'end_minute')::int;
    v_tz           := v_window->>'timezone';

    if v_weekday is null or v_start_minute is null or v_end_minute is null or v_tz is null then
      continue;
    end if;
    if v_end_minute <= v_start_minute then continue; end if;

    -- Host's "today" in their local timezone. Driving the iteration off the
    -- host-local date (instead of `current_date`, which depends on the
    -- session GUC) makes the loop independent of the session TimeZone and
    -- behaves correctly for large-offset zones (Apia +14, Marquesas -09:30,
    -- etc.) where UTC date and host-local date diverge.
    v_local_today := (now() at time zone v_tz)::date;

    for v_day in 0..13 loop
      v_local_date := v_local_today + v_day;

      -- Day-of-week computed on a *wall-clock* timestamp (no tz indirection):
      -- a `timestamp without time zone` has no GUC dependency, so extract(dow)
      -- returns the host-local weekday by construction.
      v_local_wall := (v_local_date || ' 12:00')::timestamp;
      if extract(dow from v_local_wall) <> v_weekday then
        continue;
      end if;

      -- Build the local start/end as wall clock then convert to UTC via the
      -- timezone. `at time zone v_tz` on a tz-naive timestamp interprets the
      -- value as host-local wall clock — DST-correct.
      v_slot_start := ((v_local_date || ' 00:00')::timestamp + (v_start_minute || ' minutes')::interval)
                      at time zone v_tz;
      v_window_end := ((v_local_date || ' 00:00')::timestamp + (v_end_minute   || ' minutes')::interval)
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

revoke all on function public.materialize_office_hours_slots(uuid) from public, anon, authenticated;

-- =============================================================================
-- 3. book_slot — UTC weekly bucket + explicit meeting_confirmed dispatch.
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
  -- host whose slot falls within the ISO week (Monday 00:00 UTC bucket).
  -- Pinning to UTC at BOTH ends of the expression: the inner
  -- `at time zone 'UTC'` makes date_trunc operate on a UTC wall clock
  -- (independent of the session TimeZone GUC), and the outer
  -- `at time zone 'UTC'` re-interprets the truncated wall clock back as a
  -- UTC instant (otherwise the implicit `timestamp -> timestamptz` cast
  -- would silently use the session TimeZone, re-introducing the drift).
  v_week_start := (date_trunc('week', (now() at time zone 'UTC')) at time zone 'UTC');
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
  -- existing chat surface renders it consistently. The notify_message_inserted
  -- trigger detects that the linked proposal is already 'confirmed' and
  -- suppresses the proposal-kind push — the canonical meeting_confirmed
  -- push below covers the host's notification.
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

  -- Canonical meeting_confirmed push to the host. notify_meeting_confirmed
  -- is an AFTER UPDATE trigger and the row above was born in 'confirmed'
  -- state via INSERT, so without this explicit dispatch the host gets no
  -- meeting_confirmed push at all. Payload shape mirrors notify_meeting_confirmed
  -- exactly so the mobile push handler renders identically regardless of
  -- which code path emitted it. Gated on the host's notification_preferences
  -- via should_notify, same as the trigger would have done.
  if public.should_notify(
       v_slot.host_id,
       'meeting_confirmed'::public.notification_kind,
       'push'::public.notification_channel
     ) then
    perform public.dispatch_push(
      v_slot.host_id,
      'meeting_proposals',
      v_proposal_id,
      jsonb_build_object(
        'kind',  'meeting_confirmed',
        'title', 'Meeting confirmed',
        'body',  'Your meeting has been confirmed.',
        'url',   '/(app)/chats/' || v_conversation_id
      ),
      p_kind            => 'meeting_confirmed',
      p_entity_id       => v_proposal_id,
      p_conversation_id => v_conversation_id
    );
  end if;

  return v_proposal_id;
end;
$$;

revoke all on function public.book_slot(uuid, text) from public, anon;
grant execute on function public.book_slot(uuid, text) to authenticated;
