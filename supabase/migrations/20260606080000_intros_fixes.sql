-- Intros hardening: 30-day cooldown enforcement, daily-send cap, declined_at column,
-- and an expiry job to flip stale 'delivered' rows to 'expired'.
--
-- Note on accept_intro: the canonical definition lives in 20260606000000_rls_hardening.sql
-- (which adds a blocks-check under the row lock). We intentionally do NOT redefine it here
-- so that hardening stays applied.

-- =============================================================================
-- #1 declined_at column — preferred source of truth for the decline cooldown.
-- updated_at remains as a fallback for any pre-existing declined rows (NULL).
-- =============================================================================
alter table public.intros
  add column if not exists declined_at timestamptz;

create index if not exists intros_sender_recipient_declined_idx
  on public.intros (sender_id, recipient_id, declined_at desc)
  where state = 'declined';

-- =============================================================================
-- #2 decline_intro — stamp declined_at alongside the state transition.
-- =============================================================================
create or replace function public.decline_intro(p_intro_id uuid)
returns public.intros
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_intro public.intros;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  select * into v_intro from public.intros where id = p_intro_id for update;
  if not found then raise exception 'intro not found' using errcode = 'P0002'; end if;
  if v_intro.recipient_id is distinct from v_caller then
    raise exception 'only the recipient can decline' using errcode = '42501';
  end if;
  if v_intro.state <> 'delivered'::public.intro_state then
    raise exception 'intro not in delivered state' using errcode = '22023';
  end if;
  update public.intros
     set state       = 'declined'::public.intro_state,
         declined_at = now()
   where id = p_intro_id
   returning * into v_intro;
  return v_intro;
end;
$$;
grant execute on function public.decline_intro(uuid) to authenticated;

-- =============================================================================
-- #3 send_intro — enforce 30-day decline cooldown + 20/day outbound cap.
-- Distinct SQLSTATEs so the client can map to friendly messages:
--   P0001 cooldown   →  IntroCooldownError
--   P0001 daily cap  →  IntroRateLimitError (disambiguated by MESSAGE prefix)
--   23505 duplicate  →  IntroDuplicateError (existing unique-index path; unchanged)
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

  -- 20/day outbound cap (per UTC calendar day; created_at::date is server-time).
  select count(*) into v_today_count
    from public.intros
   where sender_id = v_sender
     and created_at::date = current_date;
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
-- #4 intros_today_count — recipient-side count of intros received today.
-- Powers the inbox cap banner with server-truth instead of local-device midnight.
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
     and created_at::date = current_date;
  return v_count;
end;
$$;
grant execute on function public.intros_today_count() to authenticated;

-- =============================================================================
-- #5 expire_overdue_intros — sweep stale 'delivered' rows past expires_at.
-- pg_cron is NOT enabled in this project (no prior cron.schedule calls).
-- Invoke externally (Edge Function on a schedule, supabase-scheduler, or
-- `select cron.schedule(...)` once pg_cron is added).
-- =============================================================================
create or replace function public.expire_overdue_intros()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  with upd as (
    update public.intros
       set state = 'expired'::public.intro_state
     where state = 'delivered'::public.intro_state
       and expires_at < now()
    returning 1
  )
  select count(*) into v_count from upd;
  return v_count;
end;
$$;
revoke execute on function public.expire_overdue_intros() from public;
-- Intentionally NOT granted to authenticated — service role / cron only.
