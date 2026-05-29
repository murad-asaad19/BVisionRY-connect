-- Invite + Waitlist primitive (GTM prerequisite for an invite-gated launch).
--
-- Three tables and three SECURITY DEFINER RPCs that, together, let us:
--   * collect emails from people who want access     (public.waitlist / join_waitlist)
--   * gate sign-up behind a redeemable invite code    (public.invite_codes / redeem_invite)
--   * give every member a handful of codes to share    (ensure_invite_codes)
--   * record who-invited-whom for attribution           (public.referrals)
--
-- RLS strategy mirrors the rest of the schema (see 20260608020000_opportunities.sql):
-- clients never mutate these tables directly except the single anon/authenticated
-- INSERT path into `waitlist` (the join); every other write goes through a
-- SECURITY DEFINER RPC that reads auth.uid() internally. SELECT policies are
-- scoped to the owning / participating user.
--
-- Idempotent: tables use IF NOT EXISTS, policies are dropped-then-created, and
-- the functions are CREATE OR REPLACE — safe to re-run.

create extension if not exists citext   with schema extensions;
create extension if not exists pgcrypto with schema extensions;

-- =============================================================================
-- (1) Tables.
-- =============================================================================

-- waitlist --------------------------------------------------------------------
-- One row per email that asked for access. `invited_at` is stamped when we
-- convert them off the list (out of scope for the client surfaces here, but the
-- column exists so the conversion job has somewhere to write).
create table if not exists public.waitlist (
  id         uuid primary key default gen_random_uuid(),
  email      extensions.citext unique not null,
  created_at timestamptz not null default now(),
  invited_at timestamptz,
  note       text
);

-- invite_codes ----------------------------------------------------------------
-- Shareable codes owned by a member. `used_count` is bumped (under the RPC's
-- definer privileges) every time someone redeems the code at sign-up.
create table if not exists public.invite_codes (
  code       text primary key,
  owner_id   uuid not null references public.profiles(id) on delete cascade,
  max_uses   int not null default 1,
  used_count int not null default 0,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  constraint invite_codes_max_uses_positive check (max_uses > 0),
  constraint invite_codes_used_count_bounded check (used_count >= 0 and used_count <= max_uses)
);

create index if not exists invite_codes_owner_idx
  on public.invite_codes (owner_id, created_at desc);

-- referrals -------------------------------------------------------------------
-- The who-invited-whom edge. `referred_id` is unique so a given user can only
-- ever be attributed to one referrer (their first redeemed code wins).
create table if not exists public.referrals (
  id          uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.profiles(id) on delete cascade,
  referred_id uuid not null unique references public.profiles(id) on delete cascade,
  code        text references public.invite_codes(code) on delete set null,
  created_at  timestamptz not null default now()
);

create index if not exists referrals_referrer_idx
  on public.referrals (referrer_id, created_at desc);

-- =============================================================================
-- (2) RLS.
-- =============================================================================
alter table public.waitlist     enable row level security;
alter table public.invite_codes enable row level security;
alter table public.referrals    enable row level security;

-- waitlist: anyone (anon or authenticated) may INSERT to join. There is no
-- public SELECT — the list is private. The RPC is the preferred join path (it
-- de-dupes), but a direct INSERT is permitted for resilience; the unique index
-- on email makes a naive duplicate INSERT fail loudly, which the RPC avoids.
drop policy if exists waitlist_insert_anyone on public.waitlist;
create policy waitlist_insert_anyone
  on public.waitlist for insert to anon, authenticated
  with check (true);

-- invite_codes: an owner can read their own codes (the "invite friends" screen
-- reads these). No client INSERT/UPDATE/DELETE — all mutation via RPC.
drop policy if exists invite_codes_select_own on public.invite_codes;
create policy invite_codes_select_own
  on public.invite_codes for select to authenticated
  using (owner_id = auth.uid());

drop policy if exists invite_codes_no_direct_mutate on public.invite_codes;
create policy invite_codes_no_direct_mutate
  on public.invite_codes for all to authenticated
  using (false) with check (false);

-- referrals: either participant may read their own edges.
drop policy if exists referrals_select_participant on public.referrals;
create policy referrals_select_participant
  on public.referrals for select to authenticated
  using (referrer_id = auth.uid() or referred_id = auth.uid());

drop policy if exists referrals_no_direct_mutate on public.referrals;
create policy referrals_no_direct_mutate
  on public.referrals for all to authenticated
  using (false) with check (false);

-- =============================================================================
-- (3) RPCs.
-- =============================================================================

-- join_waitlist ---------------------------------------------------------------
-- Idempotent join: inserts the email if it isn't already on the list. Callable
-- by anon (pre-auth, from the sign-in screen) and authenticated. Validates a
-- basic email shape so we don't store obvious garbage.
create or replace function public.join_waitlist(p_email text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
begin
  if v_email = '' then
    raise exception 'An email is required.'
      using errcode = 'P0001', hint = 'email_required';
  end if;

  -- Pragmatic shape check (local-part@domain.tld). Not RFC-complete on purpose;
  -- it just rejects obvious non-emails. Real validation is the confirmation send.
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'That does not look like a valid email.'
      using errcode = 'P0001', hint = 'email_invalid';
  end if;

  insert into public.waitlist (email)
  values (v_email::extensions.citext)
  on conflict (email) do nothing;
end;
$$;

revoke all on function public.join_waitlist(text) from public;
grant execute on function public.join_waitlist(text) to anon, authenticated;

-- redeem_invite ---------------------------------------------------------------
-- Called by an authenticated user (typically right after sign-up) to consume an
-- invite code. Atomically increments used_count and records the referral edge.
-- Idempotent per redeemer: if this user already redeemed *any* code (there is at
-- most one referral row per referred_id) it returns without double-counting.
--
-- Stable error hints for the client error map:
--   invalid_code   — no such code
--   code_expired   — code exists but is past expires_at
--   code_exhausted — used_count has reached max_uses
create or replace function public.redeem_invite(p_code text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_code text := btrim(coalesce(p_code, ''));
  v_row  public.invite_codes;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  if v_code = '' then
    raise exception 'An invite code is required.'
      using errcode = 'P0001', hint = 'invalid_code';
  end if;

  -- Already attributed? No-op (idempotent). This also covers the case where the
  -- user re-submits the same code: their referral row already exists.
  if exists (select 1 from public.referrals where referred_id = v_user) then
    return;
  end if;

  -- Lock the code row so the used_count check + increment is atomic against
  -- concurrent redemptions of the same code.
  select * into v_row
    from public.invite_codes
   where code = v_code
   for update;

  if not found then
    raise exception 'That invite code is not valid.'
      using errcode = 'P0001', hint = 'invalid_code';
  end if;

  -- A user cannot redeem their own code.
  if v_row.owner_id = v_user then
    raise exception 'You cannot redeem your own invite code.'
      using errcode = 'P0001', hint = 'invalid_code';
  end if;

  if v_row.expires_at is not null and v_row.expires_at <= now() then
    raise exception 'That invite code has expired.'
      using errcode = 'P0001', hint = 'code_expired';
  end if;

  if v_row.used_count >= v_row.max_uses then
    raise exception 'That invite code has already been used up.'
      using errcode = 'P0001', hint = 'code_exhausted';
  end if;

  update public.invite_codes
     set used_count = used_count + 1
   where code = v_row.code;

  insert into public.referrals (referrer_id, referred_id, code)
  values (v_row.owner_id, v_user, v_row.code)
  on conflict (referred_id) do nothing;
end;
$$;

revoke all on function public.redeem_invite(text) from public, anon;
grant execute on function public.redeem_invite(text) to authenticated;

-- ensure_invite_codes ---------------------------------------------------------
-- Returns the caller's shareable codes, generating more if they currently own
-- fewer than p_count *unexpired* ones. New codes are 8-char base32 (Crockford,
-- no padding) with collision-retry against the primary key. Always returns the
-- full set the caller owns (newly generated + pre-existing), newest first.
create or replace function public.ensure_invite_codes(p_count int default 3)
returns setof public.invite_codes
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user      uuid := auth.uid();
  v_target    int  := greatest(coalesce(p_count, 3), 1);
  v_have      int;
  v_to_make   int;
  v_code      text;
  v_alphabet  text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; -- Crockford base32 (no I,L,O,U)
  v_attempts  int;
  i           int;
  j           int;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  select count(*) into v_have
    from public.invite_codes
   where owner_id = v_user
     and (expires_at is null or expires_at > now());

  v_to_make := v_target - v_have;

  if v_to_make > 0 then
    for i in 1 .. v_to_make loop
      v_attempts := 0;
      loop
        v_attempts := v_attempts + 1;
        -- Build an 8-char code from cryptographically-random bytes.
        v_code := '';
        for j in 1 .. 8 loop
          v_code := v_code || substr(
            v_alphabet,
            1 + (get_byte(gen_random_bytes(1), 0) % length(v_alphabet)),
            1
          );
        end loop;

        begin
          insert into public.invite_codes (code, owner_id, max_uses)
          values (v_code, v_user, 1);
          exit; -- inserted successfully
        exception when unique_violation then
          if v_attempts >= 10 then
            raise exception 'Could not generate a unique invite code.'
              using errcode = 'P0001', hint = 'code_gen_failed';
          end if;
          -- else: collision, retry with a fresh code
        end;
      end loop;
    end loop;
  end if;

  return query
    select * from public.invite_codes
     where owner_id = v_user
     order by created_at desc;
end;
$$;

revoke all on function public.ensure_invite_codes(int) from public, anon;
grant execute on function public.ensure_invite_codes(int) to authenticated;

-- =============================================================================
-- (4) Comments (self-doc for type generation).
-- =============================================================================
comment on table public.waitlist is
  'Emails collected from people requesting access pre-launch. anon/authenticated may INSERT (join); no public SELECT. Preferred join path is join_waitlist (idempotent).';
comment on table public.invite_codes is
  'Shareable invite codes owned by a member. Owners SELECT their own; all mutation via redeem_invite / ensure_invite_codes (RLS blocks direct writes).';
comment on table public.referrals is
  'who-invited-whom edges. referred_id is unique (first redeemed code wins). Participants SELECT their own; writes via redeem_invite only.';
comment on function public.join_waitlist(text) is
  'Idempotent add of an email to the waitlist. Callable by anon + authenticated. Basic email-shape validation.';
comment on function public.redeem_invite(text) is
  'Consumes an invite code for the caller (idempotent per redeemer): increments used_count and records a referral. Hints: invalid_code / code_expired / code_exhausted.';
comment on function public.ensure_invite_codes(int) is
  'Ensures the caller owns at least p_count unexpired invite codes (generating more if needed) and returns all their codes, newest first.';
