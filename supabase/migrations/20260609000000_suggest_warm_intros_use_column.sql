-- Fix suggest_warm_intros: two bugs uncovered while exercising the home tab.
--
-- (1) AMBIGUOUS COLUMN
-- PL/pgSQL flagged `cl.target_id` and `cs.target_id` as ambiguous because the
-- function's OUT parameter is also named target_id. Same class of bug as
-- get_daily_matches (fixed in 20260606090000_discovery_fixes.sql) and the
-- canonical fix is the same: add `#variable_conflict use_column` so
-- unqualified identifiers inside the function body resolve to table columns.
--
-- (2) NON-EXISTENT ENUM VALUE 'pending'
-- 20260608060000_warm_intros_fixes.sql referenced
-- `'pending'::public.intro_state` in the NOT-EXISTS subquery, but the
-- intro_state enum only has {delivered, accepted, declined, expired,
-- connected}. send_warm_request inserts warm_request rows directly with
-- state = 'delivered', and decline_intro transitions warm_requests straight
-- to 'declined' without stamping declined_at (#14). So the only "still-live"
-- state for a warm_request is 'delivered'. Dropping the 'pending' cast is the
-- correct fix and prevents an "invalid input value for enum" at every call.

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
#variable_conflict use_column
declare
  v_user uuid := auth.uid();
  v_limit int := coalesce(p_limit, 10);
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  return query
  with viewer_conn as (
    select
      case when sender_id = v_user then recipient_id else sender_id end as other_id,
      updated_at
    from public.intros
    where state = 'connected'::public.intro_state
      and (sender_id = v_user or recipient_id = v_user)
  ),
  mutual_conn as (
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
  candidate_links as (
    select target_id, mutual_id, max(link_updated_at) as link_updated_at
    from mutual_conn
    group by target_id, mutual_id
  ),
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
    and not exists (
      select 1 from public.intros ix
      where (ix.sender_id = v_user    and ix.recipient_id = cs.target_id)
         or (ix.sender_id = cs.target_id and ix.recipient_id = v_user)
         or (ix.sender_id      = v_user
             and ix.warm_target_id = cs.target_id
             and ix.kind           = 'warm_request'::public.intro_kind
             and ix.state = 'delivered'::public.intro_state)
    )
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

-- send_warm_request has the same 'pending'::intro_state bug — the #7
-- anti-shotgun check would throw at the first call for any asker. Same fix.
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

  -- #7 Anti-shotgun: only one outstanding warm_request per (asker, target).
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

  -- Note length: same window as direct intros (see send_intro).
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

-- list_connections (slice15) also tripped variable_conflict=error because the
-- OUT parameter conversation_id collides with the inner subquery's
-- `where conversation_id is not null`. Same canonical fix.
create or replace function public.list_connections()
returns table (
  user_id uuid,
  handle text,
  name text,
  photo_url text,
  primary_role public.role_kind,
  conversation_id uuid,
  connected_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
#variable_conflict use_column
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  return query
  select distinct on (other_id)
    other_id as user_id,
    p.handle::text,
    p.name,
    p.photo_url,
    p.primary_role,
    i.conversation_id,
    i.updated_at as connected_at
  from (
    select case when sender_id = v_user then recipient_id else sender_id end as other_id, *
    from public.intros
    where state = 'connected'::public.intro_state
      and (sender_id = v_user or recipient_id = v_user)
      and conversation_id is not null
  ) i
  join public.profiles p on p.id = i.other_id and p.onboarded = true
  where not exists (
    select 1 from public.blocks
    where (blocker_id = v_user and blocked_id = i.other_id)
       or (blocker_id = i.other_id and blocked_id = v_user)
  )
  order by other_id, i.updated_at desc;
end;
$$;

grant execute on function public.list_connections() to authenticated;
