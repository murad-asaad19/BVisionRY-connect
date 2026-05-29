-- Sender-side daily intro counter for the compose sheet ("Today's intros: N / cap").
--
-- The existing public.intros_today_count() counts intros the caller has
-- *received* today (recipient_id = auth.uid()); it drives the inbox banner and
-- is the wrong signal for the send-cap heads-up on the compose sheet. This
-- migration adds the sender-side companion:
--
--   public.intros_sent_today_count() -> table(used int, cap int)
--
--   used = number of rows in public.intros the caller SENT today (UTC day),
--          matching the exact cap query enforced inside send_intro /
--          send_warm_request (see 20260612000000_server_side_caps_hardening.sql):
--              sender_id = auth.uid()
--              and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date
--   cap  = public.intro_daily_cap(auth.uid()), the SAME single source of truth
--          the two send RPCs use, so the client renders a server-authoritative
--          cap rather than its own tier guess.
--
-- LIMITATION (inherited from intro_daily_cap): there is no Pro/subscription
-- representation in this DB yet, so the cap maxes out at 15 (verified) until a
-- billing column lands. When it does, extend intro_daily_cap alone — this
-- function, send_intro and send_warm_request all call it.
--
-- SECURITY DEFINER + STABLE so it can read intro_daily_cap (which is revoked
-- from client roles) while remaining a pure read. Idempotent (create or
-- replace). UTC bucketing matches intros_today_count and the send_intro cap
-- query verbatim.
create or replace function public.intros_sent_today_count()
returns table(used int, cap int)
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  return query
    select
      (
        select count(*)::int
          from public.intros
         where sender_id = v_user
           and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date
      ) as used,
      public.intro_daily_cap(v_user) as cap;
end;
$$;

grant execute on function public.intros_sent_today_count() to authenticated;
