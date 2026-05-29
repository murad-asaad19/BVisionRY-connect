-- Age gate + consent logging at sign-up (launch compliance: app-store + GDPR/CCPA).
--
-- Adds the consent columns to public.profiles and a SECURITY DEFINER RPC the
-- client calls immediately after a successful auth signup. The RPC is the
-- source of truth: it re-validates the caller's age and that BOTH the Terms of
-- Service and Privacy Policy were explicitly accepted before stamping the row.
--
-- Idempotent: safe to re-run (columns use IF NOT EXISTS, the function is
-- CREATE OR REPLACE).

alter table public.profiles add column if not exists date_of_birth date;
alter table public.profiles add column if not exists tos_accepted_at timestamptz;
alter table public.profiles add column if not exists privacy_accepted_at timestamptz;

-- Minimum age (years) required to use the service. Change this single constant
-- to adjust the gate; the RPC below derives the cutoff date from it.
create or replace function public.record_signup_consent(
  p_date_of_birth date,
  p_accept_tos     boolean,
  p_accept_privacy boolean
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  -- Minimum age in years required to use BVisionry Connect.
  c_min_age constant int := 18;
  v_caller  uuid := auth.uid();
begin
  if v_caller is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  if p_date_of_birth is null then
    raise exception 'A date of birth is required.'
      using errcode = 'P0001', hint = 'dob_required';
  end if;

  -- Age gate: the user must have turned c_min_age on or before today. Using an
  -- interval-shifted cutoff keeps leap-year birthdays correct.
  if p_date_of_birth > (current_date - make_interval(years => c_min_age)) then
    raise exception 'You must be % or older to use this service.', c_min_age
      using errcode = 'P0001', hint = 'under_age';
  end if;

  if p_accept_tos is not true or p_accept_privacy is not true then
    raise exception 'You must accept the Terms of Service and Privacy Policy.'
      using errcode = 'P0001', hint = 'consent_required';
  end if;

  update public.profiles
     set date_of_birth       = p_date_of_birth,
         tos_accepted_at     = now(),
         privacy_accepted_at = now()
   where id = v_caller;

  if not found then
    raise exception 'profile row missing for %', v_caller using errcode = 'P0002';
  end if;
end;
$$;

revoke execute on function
  public.record_signup_consent(date, boolean, boolean) from public, anon;
grant execute on function
  public.record_signup_consent(date, boolean, boolean) to authenticated;
