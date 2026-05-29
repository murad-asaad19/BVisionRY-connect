-- Server-side cap & abuse hardening (launch review priority #6)
--
-- Principle: every rate-limit / cap the Flutter client renders must be
-- ENFORCED server-side. The client is a hint surface only; never trusted.
--
-- This migration is idempotent (create or replace, create index if not
-- exists, drop ... if exists) and preserves all existing RPC logic verbatim
-- except for the specific guards described below.
--
-- ============================================================
-- 1. Tiered, server-enforced daily intro cap
-- ============================================================
-- BEFORE: send_intro and send_warm_request both enforced a FLAT 20/day
--   outbound cap, while the Flutter client (introsDailyCapForTier in
--   lib/features/intros/providers/intros_providers.dart) advertises a TIERED
--   cap: free 5 / verified 15 / Pro 40. The server cap was both wrong
--   (20 != any client tier) and not tier-aware, so a free user could send
--   up to 20 despite the UI promising 5.
--
-- AFTER: a single source of truth, public.intro_daily_cap(uuid), derives the
--   sender's cap from the same signal the client uses for the tier
--   (Profile.isVerified == verified_github_username is not null):
--       unverified  -> 5   (client "free")
--       verified    -> 15  (client "verified")
--   LIMITATION: there is NO "Pro"/subscription representation in this DB yet
--   (no subscription/plan/tier column on public.profiles; the client's
--   IntrosTier.pro is unreachable because no subscription provider exists).
--   So the server's effective maximum is 15 (verified). When a Pro/billing
--   tier lands, extend this one function — both RPCs already call it.
--   Both RPCs keep raising the SAME stable error the client maps
--   (errcode 'P0001', hint 'daily_cap' -> DailyCapException in
--   lib/core/errors/error_map.dart).
create or replace function public.intro_daily_cap(p_sender uuid)
returns integer
language sql
stable
security definer
set search_path = public, extensions
as $$
  -- 5 for unverified, 15 for verified. No Pro tier exists server-side yet.
  select case
           when exists (
             select 1 from public.profiles
             where id = p_sender
               and verified_github_username is not null
           ) then 15
           else 5
         end;
$$;

-- Internal helper: callable only from other SECURITY DEFINER RPCs (which run
-- as the definer), never directly. Revoke from every client-facing role so it
-- is not exposed via PostgREST /rpc and does not trip the
-- *_security_definer_function_executable advisor.
revoke all on function public.intro_daily_cap(uuid) from public, anon, authenticated;

-- 1a. send_intro: replace the flat 20/day cap with the tiered cap.
--     Body is re-issued verbatim from the live definition; ONLY the cap
--     literal (20) is replaced with public.intro_daily_cap(v_sender). All
--     other logic (self-check, note length, recipient availability, 30-day
--     decline cooldown, insert) is preserved exactly.
create or replace function public.send_intro(p_recipient_id uuid, p_note text)
 returns intros
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_sender uuid := auth.uid();
  v_intro  public.intros;
  v_today_count int;
  v_cap int;
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

  -- Tiered outbound daily cap — explicit UTC calendar day. Server-enforced.
  v_cap := public.intro_daily_cap(v_sender);
  select count(*) into v_today_count
    from public.intros
   where sender_id = v_sender
     and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date;
  if v_today_count >= v_cap then
    raise exception 'daily cap reached'
      using errcode = 'P0001', hint = 'daily_cap';
  end if;

  insert into public.intros (sender_id, recipient_id, note)
  values (v_sender, p_recipient_id, btrim(p_note))
  returning * into v_intro;
  return v_intro;
end;
$function$;

-- 1b. send_warm_request: same flat-20 -> tiered cap swap. All triangle /
--     connection / block / dup-target validation preserved verbatim; ONLY
--     the cap literal is replaced.
create or replace function public.send_warm_request(p_mutual_id uuid, p_target_id uuid, p_note text)
 returns uuid
 language plpgsql
 security definer
 set search_path to 'public', 'extensions'
as $function$
declare
  v_sender uuid := auth.uid();
  v_today_count int;
  v_cap int;
  v_intro_id uuid;
begin
  if v_sender is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  if p_mutual_id is null or p_target_id is null then
    raise exception 'mutual_id and target_id are required' using errcode = '22023';
  end if;
  if v_sender = p_mutual_id or v_sender = p_target_id or p_mutual_id = p_target_id then
    raise exception 'invalid triangle' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.intros
    where sender_id      = v_sender
      and warm_target_id = p_target_id
      and kind           = 'warm_request'::public.intro_kind
      and state          = 'delivered'::public.intro_state
  ) then
    raise exception 'warm request already pending for target'
      using errcode = 'P0001', hint = 'warm_request_pending';
  end if;

  if char_length(btrim(p_note)) < 80 or char_length(btrim(p_note)) > 400 then
    raise exception 'note must be 80-400 characters' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = p_mutual_id and onboarded = true
  ) then
    raise exception 'mutual not available' using errcode = 'P0002';
  end if;
  if not exists (
    select 1 from public.profiles
    where id = p_target_id
      and onboarded = true
      and private_mode = false
      and suspended_at is null
  ) then
    raise exception 'target not available' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.blocks
    where (blocker_id = v_sender    and blocked_id = p_mutual_id)
       or (blocker_id = p_mutual_id and blocked_id = v_sender)
       or (blocker_id = v_sender    and blocked_id = p_target_id)
       or (blocker_id = p_target_id and blocked_id = v_sender)
       or (blocker_id = p_mutual_id and blocked_id = p_target_id)
       or (blocker_id = p_target_id and blocked_id = p_mutual_id)
  ) then
    raise exception 'blocked' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.intros
    where state = 'connected'::public.intro_state
      and (
        (sender_id = v_sender    and recipient_id = p_mutual_id)
        or
        (sender_id = p_mutual_id and recipient_id = v_sender)
      )
  ) then
    raise exception 'no connection to mutual' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.intros
    where state = 'connected'::public.intro_state
      and (
        (sender_id = p_mutual_id and recipient_id = p_target_id)
        or
        (sender_id = p_target_id and recipient_id = p_mutual_id)
      )
  ) then
    raise exception 'mutual has no connection to target' using errcode = '42501';
  end if;

  if exists (
    select 1 from public.intros
    where (sender_id = v_sender    and recipient_id = p_target_id)
       or (sender_id = p_target_id and recipient_id = v_sender)
  ) then
    raise exception 'intro to target already exists' using errcode = '23505';
  end if;

  if exists (
    select 1 from public.intros
    where sender_id      = v_sender
      and recipient_id   = p_mutual_id
      and kind           = 'warm_request'::public.intro_kind
      and warm_target_id = p_target_id
      and state          = 'delivered'::public.intro_state
  ) then
    raise exception 'warm request already pending' using errcode = '23505';
  end if;

  -- Tiered outbound daily cap — explicit UTC calendar day. Server-enforced.
  v_cap := public.intro_daily_cap(v_sender);
  select count(*) into v_today_count
    from public.intros
   where sender_id = v_sender
     and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date;
  if v_today_count >= v_cap then
    raise exception 'daily cap reached'
      using errcode = 'P0001', hint = 'daily_cap';
  end if;

  insert into public.intros (
    sender_id, recipient_id, note, state, kind, warm_target_id
  ) values (
    v_sender, p_mutual_id, btrim(p_note),
    'delivered'::public.intro_state,
    'warm_request'::public.intro_kind,
    p_target_id
  )
  returning id into v_intro_id;

  return v_intro_id;
end;
$function$;

-- ============================================================
-- 2. Warm-intro anti-shotgun: backing unique index
-- ============================================================
-- send_warm_request's "warm request already pending" / "already exists"
-- checks are read-then-write and therefore TOCTOU-vulnerable: two concurrent
-- calls routed through DIFFERENT mutuals to the SAME target can both pass the
-- existence check and both insert (a "shotgun" of warm requests at one
-- target). This partial unique index makes the database the final arbiter —
-- a second concurrent delivered warm request from the same sender to the same
-- target fails atomically with 23505, which the client already understands.
create unique index if not exists intros_warm_target_uq
  on public.intros (sender_id, warm_target_id)
  where (
    kind = 'warm_request'::public.intro_kind
    and state = 'delivered'::public.intro_state
    and warm_target_id is not null
  );

-- ============================================================
-- 3. Report bombing: one report per (reporter, target) per UTC day
-- ============================================================
-- report_target had NO guard, so a single reporter could spam unlimited
-- reports against one target. We add a partial unique index keyed on
-- (reporter_id, target_type, target_id, UTC-day) and make report_target
-- idempotent via ON CONFLICT DO NOTHING — a same-day repeat is silently
-- collapsed (no duplicate row stored, no error surfaced), preserving the
-- existing `returns void` contract while neutralising report bombing. A
-- genuine new-day report still lands. Index uses an IMMUTABLE day expression
-- (timezone(text, timestamptz) is immutable) so it is index-safe.
create unique index if not exists reports_reporter_target_day_uq
  on public.reports (
    reporter_id,
    target_type,
    target_id,
    (timezone('UTC', created_at)::date)
  );

create or replace function public.report_target(p_target_type text, p_target_id uuid, p_reason text, p_note text)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if p_target_type = 'profile' and p_target_id = v_user then
    raise exception 'cannot report self' using errcode='22023';
  end if;
  -- Idempotent on (reporter, target, UTC day): re-reporting the same target
  -- the same day is a silent no-op (anti report-bombing). Backed by
  -- reports_reporter_target_day_uq.
  insert into public.reports (reporter_id, target_type, target_id, reason, note)
  values (
    v_user,
    p_target_type::public.report_target_type,
    p_target_id,
    p_reason::public.report_reason,
    p_note
  )
  on conflict (reporter_id, target_type, target_id, (timezone('UTC', created_at)::date))
  do nothing;
end;
$function$;

-- ============================================================
-- 4. Tighten the messages last-active trigger function grant
-- ============================================================
-- stamp_sender_last_active() is an AFTER-INSERT trigger function only; it must
-- never be invokable via PostgREST /rpc. The prior migration revoked it from
-- public+anon but left the `authenticated` EXECUTE grant, which trips the
-- authenticated_security_definer_function_executable advisor. Trigger
-- functions fire as the table owner regardless of caller EXECUTE, so revoking
-- from every client role is safe and closes the advisor finding.
revoke all on function public.stamp_sender_last_active() from public, anon, authenticated;
