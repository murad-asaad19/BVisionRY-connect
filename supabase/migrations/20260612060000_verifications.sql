-- Verifications: generic manual-review role-proof system for Founder & Investor.
--
-- Models the same "service_role reviews, no in-app admin UI" pattern as the
-- `reports` table (20260523000000_slice9_privacy.sql): users SUBMIT a proof via
-- a SECURITY DEFINER RPC, the row lands `pending`, and the team approves /
-- rejects it offline through service_role (the review runbook). The owner can
-- read their own submissions to render status; no one else can read, and no one
-- can INSERT/UPDATE directly — writes flow exclusively through the RPCs.
--
-- Auto-verification (domain-email OTP, Crunchbase API) is explicitly out of
-- scope; the `payload` jsonb just carries whatever evidence the kind needs
-- (work email, /team page URL, Crunchbase URL, portfolio links) for a human
-- reviewer. GitHub "Builder" verification stays on its own `profiles.verified_*`
-- columns (20260522000000_slice7_verification.sql) and is untouched here.

create type public.verification_kind as enum (
  'founder_domain_email',
  'founder_team_page',
  'investor_domain_email',
  'investor_crunchbase',
  'investor_portfolio'
);

create type public.verification_status as enum (
  'pending',
  'approved',
  'rejected'
);

create table public.verifications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  kind         public.verification_kind not null,
  status       public.verification_status not null default 'pending',
  payload      jsonb not null default '{}',
  note         text,
  reviewed_by  uuid,
  reviewed_at  timestamptz,
  created_at   timestamptz not null default now(),
  constraint verifications_note_len check (note is null or char_length(note) <= 1000)
);

create index verifications_user_idx on public.verifications (user_id);
create index verifications_status_idx on public.verifications (status);

-- One live submission per (user, kind): a user may only have a single
-- pending-or-approved row per proof. Rejected rows are excluded so a user can
-- re-submit after a rejection (the new row reuses the same partial-unique slot
-- once the rejected one no longer counts).
create unique index verifications_one_live_per_kind
  on public.verifications (user_id, kind)
  where status <> 'rejected';

alter table public.verifications enable row level security;

-- Owner may read their own submissions (to render status pills). No select for
-- others; service_role bypasses RLS for the review path (mirrors `reports`).
create policy verifications_select_own on public.verifications
  for select using (user_id = auth.uid());
-- No insert/update/delete policies = writes only via the SECURITY DEFINER RPCs.

-- ---------------------------------------------------------------------------
-- RPCs (member path) — submit + list own.
-- ---------------------------------------------------------------------------

-- submit_verification(p_kind text, p_payload jsonb default '{}')
--
-- Inserts a fresh `pending` row for the caller. Raises a stable hint when a
-- live submission already exists so the client error-map can branch:
--   * already_approved — the caller is already verified for this kind.
--   * already_pending  — a submission is awaiting review.
create or replace function public.submit_verification(
  p_kind text,
  p_payload jsonb default '{}'
)
returns public.verifications
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_kind public.verification_kind := p_kind::public.verification_kind;
  v_existing public.verification_status;
  v_row public.verifications;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  select status into v_existing
  from public.verifications
  where user_id = v_user
    and kind = v_kind
    and status <> 'rejected'
  limit 1;

  if v_existing = 'approved' then
    raise exception 'already approved' using errcode='P0001', hint='already_approved';
  elsif v_existing = 'pending' then
    raise exception 'already pending' using errcode='P0001', hint='already_pending';
  end if;

  insert into public.verifications (user_id, kind, payload)
  values (v_user, v_kind, coalesce(p_payload, '{}'::jsonb))
  returning * into v_row;

  return v_row;
end;
$$;
grant execute on function public.submit_verification(text, jsonb) to authenticated;

-- list_my_verifications() — the caller's submissions, newest-first. RLS would
-- already scope a direct select, but the RPC keeps the client surface uniform
-- with the rest of the verification feature (and trims the payload, which the
-- UI never needs back).
create or replace function public.list_my_verifications()
returns table (
  id          uuid,
  kind        public.verification_kind,
  status      public.verification_status,
  created_at  timestamptz,
  reviewed_at timestamptz,
  note        text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  return query
  select v.id, v.kind, v.status, v.created_at, v.reviewed_at, v.note
  from public.verifications v
  where v.user_id = v_user
  order by v.created_at desc;
end;
$$;
grant execute on function public.list_my_verifications() to authenticated;

-- ---------------------------------------------------------------------------
-- RPCs (team review path) — approve / reject. service_role only.
--
-- These are the in-DB half of the manual-review runbook: an operator connected
-- as service_role calls them to grant or deny a pending proof. They are
-- REVOKED from public/anon/authenticated so no client can self-approve.
-- ---------------------------------------------------------------------------

create or replace function public.approve_verification(p_id uuid)
returns public.verifications
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.verifications;
begin
  update public.verifications
  set status = 'approved',
      note = null,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_id
  returning * into v_row;

  if not found then
    raise exception 'verification not found' using errcode='P0002';
  end if;

  return v_row;
end;
$$;

create or replace function public.reject_verification(p_id uuid, p_note text)
returns public.verifications
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.verifications;
begin
  update public.verifications
  set status = 'rejected',
      note = p_note,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_id
  returning * into v_row;

  if not found then
    raise exception 'verification not found' using errcode='P0002';
  end if;

  return v_row;
end;
$$;

-- Lock the review RPCs to service_role only (default grant is to public).
revoke execute on function public.approve_verification(uuid) from public, anon, authenticated;
revoke execute on function public.reject_verification(uuid, text) from public, anon, authenticated;
grant execute on function public.approve_verification(uuid) to service_role;
grant execute on function public.reject_verification(uuid, text) to service_role;
