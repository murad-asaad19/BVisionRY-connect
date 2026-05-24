-- Feature-fix follow-up migration (slice review hardening).
--
-- Touches three areas. Each block is idempotent and can be re-applied safely:
--   1. Intros — switch send_intro / intros_today_count to explicit UTC bucketing
--      so the cap can't be bypassed by a client/server time-zone mismatch.
--   2. Meetings — replace pending_meeting_reviews with a per-conversation
--      overload so PostMeetingPrompt can scope the prompt to the chat it's
--      rendered inside (rather than polling globally and showing the wrong
--      meeting in the wrong thread).
--   3. Profiles — harden check_handle_available to reject null / empty /
--      malformed input at the RPC boundary instead of trusting client-side
--      validation.
--
-- Plus a one-shot backfill for legacy declined intros whose declined_at was
-- never stamped (pre-20260606080000 rows). updated_at is the closest proxy.

-- =============================================================================
-- (1) send_intro — UTC calendar-day bucketing for the 20/day outbound cap.
-- created_at::date implicitly casts at session TZ; explicit `at time zone 'UTC'`
-- guarantees the cap window matches every other UTC-stamped boundary in the
-- system (cron jobs, daily picks, expiry sweep).
-- =============================================================================
create or replace function public.send_intro(p_recipient_id uuid, p_note text)
returns public.intros
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender uuid := auth.uid();
  v_intro  public.intros;
  v_today_count int;
begin
  if v_sender is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  if v_sender = p_recipient_id then raise exception 'cannot intro to self' using errcode = '22023'; end if;
  if char_length(btrim(p_note)) < 80 or char_length(btrim(p_note)) > 400 then
    raise exception 'note must be 80-400 characters' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles where id = p_recipient_id and onboarded = true) then
    raise exception 'recipient not available' using errcode = 'P0002';
  end if;

  -- 30-day cooldown after a prior decline from the same recipient.
  if exists (
    select 1 from public.intros
    where sender_id = v_sender
      and recipient_id = p_recipient_id
      and state = 'declined'::public.intro_state
      and coalesce(declined_at, updated_at) > now() - interval '30 days'
  ) then
    raise exception 'cooldown active'
      using errcode = 'P0001', hint = 'cooldown';
  end if;

  -- 20/day outbound cap — explicit UTC calendar day.
  select count(*) into v_today_count
    from public.intros
   where sender_id = v_sender
     and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date;
  if v_today_count >= 20 then
    raise exception 'daily cap reached'
      using errcode = 'P0001', hint = 'daily_cap';
  end if;

  insert into public.intros (sender_id, recipient_id, note)
  values (v_sender, p_recipient_id, btrim(p_note))
  returning * into v_intro;
  return v_intro;
end;
$$;
grant execute on function public.send_intro(uuid, text) to authenticated;

-- =============================================================================
-- (2) intros_today_count — same UTC bucketing for the recipient-side counter
-- that powers the inbox cap banner.
-- =============================================================================
create or replace function public.intros_today_count()
returns int
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_count int;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  select count(*) into v_count
    from public.intros
   where recipient_id = v_user
     and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date;
  return v_count;
end;
$$;
grant execute on function public.intros_today_count() to authenticated;

-- =============================================================================
-- (3) pending_meeting_reviews — add an optional p_conversation_id filter.
-- CREATE OR REPLACE cannot add a parameter to an existing function, even a
-- defaulted one (a different signature is a different function), so the
-- previous zero-arg version must be dropped first.
-- =============================================================================
drop function if exists public.pending_meeting_reviews();

create function public.pending_meeting_reviews(p_conversation_id uuid default null)
returns setof public.meeting_proposals
language sql
stable
security definer
set search_path = public
as $$
  select mp.*
    from public.meeting_proposals mp
    join public.conversations c on c.id = mp.conversation_id
   where (c.participant_a_id = auth.uid() or c.participant_b_id = auth.uid())
     and (p_conversation_id is null or mp.conversation_id = p_conversation_id)
     and mp.state = 'confirmed'::public.meeting_state
     and mp.confirmed_slot is not null
     and mp.confirmed_slot + (mp.duration_minutes || ' minutes')::interval < now()
     and mp.confirmed_slot > now() - interval '14 days'
     and not exists (
       select 1 from public.meeting_reviews mr
        where mr.meeting_id = mp.id
          and mr.reviewer_id = auth.uid()
     )
   order by mp.confirmed_slot desc
   limit 20;
$$;

grant execute on function public.pending_meeting_reviews(uuid) to authenticated;

-- =============================================================================
-- (4) check_handle_available — reject null / empty / format-violating input
-- at the RPC boundary. Same regex as the profiles_handle_format CHECK so the
-- RPC's "available" answer is consistent with whether INSERT would succeed.
-- =============================================================================
create or replace function public.check_handle_available(p_handle text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if p_handle is null
     or btrim(p_handle) = ''
     or not (p_handle::extensions.citext operator(extensions.~)
       '^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$'::extensions.citext) then
    return false;
  end if;
  return not exists (
    select 1 from public.profiles
    where handle = p_handle::extensions.citext
  );
end;
$$;
grant execute on function public.check_handle_available(text) to authenticated;

-- =============================================================================
-- (5) Backfill declined_at for legacy intros (pre-20260606080000_intros_fixes).
-- Idempotent: `where ... declined_at is null` is a no-op on already-stamped rows.
-- =============================================================================
update public.intros
   set declined_at = updated_at
 where state = 'declined'::public.intro_state
   and declined_at is null;
