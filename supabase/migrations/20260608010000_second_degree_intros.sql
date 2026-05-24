-- 2nd-degree warm-intro suggestions.
--
-- Adds three RPCs on top of the existing intros table to support a
-- viewer asking a mutual connection to introduce them to a third
-- party, and for the mutual to forward the request to that target.
--
-- The intros table gains TWO new columns:
--
--   * kind public.intro_kind (default 'direct')
--       Distinguishes the three intro flavours:
--         direct        — viewer → target, classic send_intro.
--         warm_request  — viewer → mutual asking for a forward.
--                         warm_target_id = the target the viewer wants
--                         to meet.
--         warm_forward  — created by forward_warm_intro on behalf of
--                         the original asker. sender_id = asker,
--                         recipient_id = target. warm_target_id
--                         back-references the mutual who forwarded
--                         (so the recipient can render "Via Alice").
--
--   * warm_target_id uuid references profiles(id)
--       CHECK constraint enforces the column is null iff kind='direct'
--       and not null iff kind in ('warm_request','warm_forward').
--
-- RPCs (all SECURITY DEFINER, search_path = public, extensions,
-- granted to authenticated only):
--
--   * suggest_warm_intros(p_limit int default 10)
--       Returns up to N target profiles the viewer has ≥1 mutual with
--       but no existing intros row with (in any state). Excludes
--       blocks, suspended/private profiles, and the viewer themself.
--       Ranked by mutual_count desc, then profiles.created_at asc.
--       top_mutual_* fields point at the most-recently-connected
--       mutual.
--
--   * send_warm_request(p_mutual_id, p_target_id, p_note)
--       Validates the viewer↔mutual↔target triangle is two solid
--       connections, no blocks anywhere in the triangle, and respects
--       the existing daily intros cap (intros_today_count counts
--       warm_requests + direct sends in the same bucket). Inserts a
--       warm_request row and returns its id.
--
--   * forward_warm_intro(p_intro_id, p_note)
--       Called by the mutual (recipient of the warm_request). Creates
--       a new warm_forward row on behalf of the original asker pointed
--       at the target, marks the original warm_request as connected
--       (it's done), and returns the new (forward) intro id. The note
--       on the forward is what Alice composes for Bob ("meet my
--       friend Carla…").

-- =============================================================================
-- (1) Schema extension: intro_kind enum + warm_target_id column.
-- =============================================================================
create type public.intro_kind as enum ('direct', 'warm_request', 'warm_forward');

alter table public.intros
  add column kind public.intro_kind not null default 'direct',
  add column warm_target_id uuid references public.profiles(id) on delete set null;

alter table public.intros
  add constraint intros_warm_target_consistency check (
    (kind = 'direct' and warm_target_id is null)
    or (kind in ('warm_request', 'warm_forward') and warm_target_id is not null)
  );

create index intros_warm_target_idx
  on public.intros (warm_target_id)
  where warm_target_id is not null;

comment on column public.intros.kind is
  'Intro flavour: direct = viewer→target, warm_request = viewer→mutual asking for a forward, warm_forward = mutual-forwarded intro on behalf of the asker.';
comment on column public.intros.warm_target_id is
  'For warm_request: the third-party the viewer wants to be introduced to. For warm_forward: back-pointer to the mutual who forwarded.';

-- =============================================================================
-- (2) suggest_warm_intros — viewer-scoped 2nd-degree suggestions.
-- =============================================================================
create or replace function public.suggest_warm_intros(p_limit int default 10)
returns table (
  target_id uuid,
  target_handle text,
  target_name text,
  target_photo_url text,
  target_primary_role public.role_kind,
  target_goal_type public.goal_type,
  mutual_count int,
  top_mutual_id uuid,
  top_mutual_name text,
  top_mutual_handle text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_limit int := coalesce(p_limit, 10);
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  return query
  with viewer_conn as (
    -- Users the viewer is connected to. Mirrors list_connections().
    select
      case when sender_id = v_user then recipient_id else sender_id end as other_id,
      updated_at
    from public.intros
    where state = 'connected'::public.intro_state
      and (sender_id = v_user or recipient_id = v_user)
  ),
  mutual_conn as (
    -- For each viewer-connection M, find all of M's connections X. X is
    -- a candidate "target" — someone the viewer can reach via M.
    select
      vc.other_id as mutual_id,
      vc.updated_at as mutual_connected_at,
      case when i.sender_id = vc.other_id then i.recipient_id else i.sender_id end as target_id,
      i.updated_at as link_updated_at
    from viewer_conn vc
    join public.intros i
      on i.state = 'connected'::public.intro_state
     and (i.sender_id = vc.other_id or i.recipient_id = vc.other_id)
    where (case when i.sender_id = vc.other_id then i.recipient_id else i.sender_id end) <> v_user
  ),
  -- Per (target, mutual) deduped — same mutual could connect to target via several rows.
  candidate_links as (
    select target_id, mutual_id, max(link_updated_at) as link_updated_at
    from mutual_conn
    group by target_id, mutual_id
  ),
  -- Aggregate to (target) → number of distinct mutuals + which mutual is most recent.
  candidate_stats as (
    select
      cl.target_id,
      count(distinct cl.mutual_id)::int as mutual_count,
      (
        select cl2.mutual_id
        from candidate_links cl2
        where cl2.target_id = cl.target_id
        order by cl2.link_updated_at desc
        limit 1
      ) as top_mutual_id
    from candidate_links cl
    group by cl.target_id
  )
  select
    cs.target_id,
    tp.handle::text as target_handle,
    tp.name as target_name,
    tp.photo_url as target_photo_url,
    tp.primary_role as target_primary_role,
    tp.goal_type as target_goal_type,
    cs.mutual_count,
    cs.top_mutual_id,
    mp.name as top_mutual_name,
    mp.handle::text as top_mutual_handle
  from candidate_stats cs
  join public.profiles tp on tp.id = cs.target_id
  join public.profiles mp on mp.id = cs.top_mutual_id
  where tp.onboarded = true
    and tp.private_mode = false
    and tp.suspended_at is null
    -- Exclude anyone the viewer already has an intros row with (any state, any kind).
    and not exists (
      select 1 from public.intros ix
      where (ix.sender_id = v_user    and ix.recipient_id = cs.target_id)
         or (ix.sender_id = cs.target_id and ix.recipient_id = v_user)
    )
    -- Exclude blocks in either direction (viewer ↔ target).
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = v_user      and b.blocked_id = cs.target_id)
         or (b.blocker_id = cs.target_id and b.blocked_id = v_user)
    )
  order by cs.mutual_count desc, tp.created_at asc
  limit v_limit;
end;
$$;

revoke all on function public.suggest_warm_intros(int) from public, anon;
grant execute on function public.suggest_warm_intros(int) to authenticated;

comment on function public.suggest_warm_intros(int) is
  'Returns up to p_limit target profiles the viewer has at least one mutual connection with but no existing intros row with (in any state). Excludes blocked / suspended / private profiles. Ordered by mutual_count desc, then by profile creation date asc. top_mutual_* fields point at the most-recently-connected mutual.';

-- =============================================================================
-- (3) send_warm_request — viewer asks their mutual to introduce them to target.
-- =============================================================================
create or replace function public.send_warm_request(
  p_mutual_id uuid,
  p_target_id uuid,
  p_note text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_sender uuid := auth.uid();
  v_today_count int;
  v_intro_id uuid;
begin
  if v_sender is null then raise exception 'unauthenticated' using errcode = '28000'; end if;
  if p_mutual_id is null or p_target_id is null then
    raise exception 'mutual_id and target_id are required' using errcode = '22023';
  end if;
  if v_sender = p_mutual_id or v_sender = p_target_id or p_mutual_id = p_target_id then
    raise exception 'invalid triangle' using errcode = '22023';
  end if;

  -- Note length: same window as direct intros (see send_intro).
  if char_length(btrim(p_note)) < 80 or char_length(btrim(p_note)) > 400 then
    raise exception 'note must be 80-400 characters' using errcode = '22023';
  end if;

  -- Mutual must be onboarded; target must be onboarded + not private + not suspended.
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

  -- Block check across the whole triangle.
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

  -- viewer↔mutual must be a connection.
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

  -- mutual↔target must be a connection.
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

  -- viewer must NOT already have any intros row with the target (any state).
  if exists (
    select 1 from public.intros
    where (sender_id = v_sender    and recipient_id = p_target_id)
       or (sender_id = p_target_id and recipient_id = v_sender)
  ) then
    raise exception 'intro to target already exists' using errcode = '23505';
  end if;

  -- viewer must NOT already have a pending warm_request to the same mutual for the same target.
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

  -- 20/day outbound cap — warm_requests count toward the same bucket as send_intro.
  select count(*) into v_today_count
    from public.intros
   where sender_id = v_sender
     and (created_at at time zone 'UTC')::date = (now() at time zone 'UTC')::date;
  if v_today_count >= 20 then
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
$$;

revoke all on function public.send_warm_request(uuid, uuid, text) from public, anon;
grant execute on function public.send_warm_request(uuid, uuid, text) to authenticated;

comment on function public.send_warm_request(uuid, uuid, text) is
  'Viewer asks their mutual to introduce them to target. Validates both legs of the viewer↔mutual↔target triangle are real connections, blocks in any leg fail, target must be reachable (onboarded + not private + not suspended), and the request counts toward the existing daily outbound intros cap.';

-- =============================================================================
-- (4) forward_warm_intro — mutual forwards the warm_request to the target.
-- =============================================================================
create or replace function public.forward_warm_intro(
  p_intro_id uuid,
  p_note text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_caller uuid := auth.uid();
  v_request public.intros;
  v_new_id uuid;
begin
  if v_caller is null then raise exception 'unauthenticated' using errcode = '28000'; end if;

  select * into v_request
    from public.intros
   where id = p_intro_id
   for update;

  if not found then raise exception 'intro not found' using errcode = 'P0002'; end if;
  if v_request.kind <> 'warm_request'::public.intro_kind then
    raise exception 'intro is not a warm request' using errcode = '22023';
  end if;
  if v_request.recipient_id is distinct from v_caller then
    raise exception 'only the warm-request recipient can forward' using errcode = '42501';
  end if;
  if v_request.state <> 'delivered'::public.intro_state then
    raise exception 'warm request not in delivered state' using errcode = '22023';
  end if;
  if v_request.sender_id is null or v_request.warm_target_id is null then
    raise exception 'warm request missing asker or target' using errcode = 'P0002';
  end if;

  -- Note length: same window as direct intros.
  if char_length(btrim(p_note)) < 80 or char_length(btrim(p_note)) > 400 then
    raise exception 'note must be 80-400 characters' using errcode = '22023';
  end if;

  -- Re-check no block between asker and target before synthesising the new intro.
  if exists (
    select 1 from public.blocks
    where (blocker_id = v_request.sender_id      and blocked_id = v_request.warm_target_id)
       or (blocker_id = v_request.warm_target_id and blocked_id = v_request.sender_id)
  ) then
    raise exception 'blocked' using errcode = '42501';
  end if;

  -- Target must still be reachable.
  if not exists (
    select 1 from public.profiles
    where id = v_request.warm_target_id
      and onboarded = true
      and suspended_at is null
  ) then
    raise exception 'target not available' using errcode = 'P0002';
  end if;

  -- Synthesise the new forward intro on behalf of the original asker.
  -- warm_target_id back-references the mutual (v_caller) so the
  -- target's UI can render "Via Alice" under the sender's name.
  insert into public.intros (
    sender_id, recipient_id, note, state, kind, warm_target_id
  ) values (
    v_request.sender_id,
    v_request.warm_target_id,
    btrim(p_note),
    'delivered'::public.intro_state,
    'warm_forward'::public.intro_kind,
    v_caller
  )
  returning id into v_new_id;

  -- Close out the original warm_request (it's done — the forward happened).
  update public.intros
     set state      = 'connected'::public.intro_state,
         updated_at = now()
   where id = v_request.id;

  return v_new_id;
end;
$$;

revoke all on function public.forward_warm_intro(uuid, text) from public, anon;
grant execute on function public.forward_warm_intro(uuid, text) to authenticated;

comment on function public.forward_warm_intro(uuid, text) is
  'Called by the recipient of a warm_request to forward the intro to the original target. Creates a new warm_forward intro on behalf of the asker (sender_id = asker, recipient_id = target, warm_target_id = forwarder), and marks the original warm_request as connected. Blocks between asker and target are re-checked at forward time.';
