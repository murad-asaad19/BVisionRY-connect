-- Profile signals: surface trust cues on profile views.
--
-- get_profile_signals(p_target) returns a single row aggregating two
-- signals shown on a profile:
--
--   1. mutual_connection_count + mutual_top_user_ids:
--      |connections(viewer) ∩ connections(target)|, where a "connection"
--      is derived from intros where state='connected' (in either
--      direction), matching the canonical pattern used by
--      public.list_connections(). The top 5 mutual user ids — ordered by
--      most-recent intro updated_at — are returned so the client can
--      render avatar chips without a follow-up query.
--
--   2. avg_meeting_rating + total_meeting_reviews:
--      Aggregates public.meeting_reviews where the *reviewee* is
--      p_target. meeting_reviews stores `outcome text` (one of
--      'useful' / 'not_useful' / 'no_show') rather than a numeric
--      rating, and does not denormalise the reviewee id — the reviewee
--      is the OTHER participant of the meeting's conversation. We map
--      outcome → 1-5 for a single user-facing trust score:
--          useful     → 5
--          not_useful → 2
--          no_show    → 1
--      and average those mapped values, rounded to 1 decimal.
--
--      avg_meeting_rating is DELIBERATELY hidden (null) when
--      total_meeting_reviews < 3 — a single outcome dominates and is
--      meaningless. The total is always exposed so the UI can still
--      say "(2 reviews)" if it wants, but the threshold is enforced
--      at the RPC layer, not in the client.
--
-- Visibility rules:
--   * Unauthenticated callers raise 'unauthenticated' (28000).
--   * Viewer == target → zeros / nulls (no point showing signals on
--     your own profile, and self-reviews are nonsensical).
--   * Block in either direction (viewer↔target) → zeros / nulls so
--     we don't leak relationship data through derived signals.
--   * Mutual list also excludes anyone the viewer has blocked or who
--     has blocked the viewer, to match the existing privacy contract.
--
-- security definer + grant authenticated only.

create or replace function public.get_profile_signals(p_target uuid)
returns table (
  mutual_connection_count int,
  mutual_top_user_ids uuid[],
  avg_meeting_rating numeric(2,1),
  total_meeting_reviews int
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_blocked boolean;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  -- Self-view: don't show signals on your own profile.
  if v_user = p_target then
    return query select 0, array[]::uuid[], null::numeric(2,1), 0;
    return;
  end if;

  -- Block in either direction: zero everything out (no data leak).
  select exists (
    select 1 from public.blocks
    where (blocker_id = v_user   and blocked_id = p_target)
       or (blocker_id = p_target and blocked_id = v_user)
  ) into v_blocked;

  if v_blocked then
    return query select 0, array[]::uuid[], null::numeric(2,1), 0;
    return;
  end if;

  return query
  with viewer_conn as (
    -- All users the VIEWER is connected to. Mirrors list_connections().
    select
      case when sender_id = v_user then recipient_id else sender_id end as other_id,
      updated_at
    from public.intros
    where state = 'connected'::public.intro_state
      and (sender_id = v_user or recipient_id = v_user)
  ),
  target_conn as (
    -- All users the TARGET is connected to.
    select
      case when sender_id = p_target then recipient_id else sender_id end as other_id,
      updated_at
    from public.intros
    where state = 'connected'::public.intro_state
      and (sender_id = p_target or recipient_id = p_target)
  ),
  mutual as (
    -- Pair the two sides on the shared "other" user. Take the more
    -- recent of the two updated_at stamps so the avatar ordering
    -- prefers freshly-strengthened relationships. Exclude blocks in
    -- either direction so a user the viewer blocked never shows up
    -- as a mutual chip.
    select
      v.other_id,
      greatest(v.updated_at, t.updated_at) as recency
    from viewer_conn v
    join target_conn t on t.other_id = v.other_id
    where v.other_id <> v_user
      and v.other_id <> p_target
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = v_user        and b.blocked_id = v.other_id)
           or (b.blocker_id = v.other_id    and b.blocked_id = v_user)
      )
  ),
  mutual_dedup as (
    -- A user could be reached via multiple intro rows; collapse to
    -- one row per other_id, keeping the most recent recency.
    select other_id, max(recency) as recency
    from mutual
    group by other_id
  ),
  mutual_top as (
    select other_id
    from mutual_dedup
    order by recency desc
    limit 5
  ),
  -- Reviews ABOUT p_target. The reviewee is the meeting participant
  -- who is NOT the reviewer; outcome is mapped to a 1-5 score so we
  -- can present a single average.
  target_reviews as (
    select
      mr.id,
      case mr.outcome
        when 'useful'     then 5
        when 'not_useful' then 2
        when 'no_show'    then 1
      end::int as score
    from public.meeting_reviews mr
    join public.meeting_proposals mp on mp.id = mr.meeting_id
    join public.conversations      c  on c.id = mp.conversation_id
    where mr.reviewer_id <> p_target
      and (
        (c.participant_a_id = p_target and c.participant_b_id = mr.reviewer_id)
        or
        (c.participant_b_id = p_target and c.participant_a_id = mr.reviewer_id)
      )
  ),
  review_stats as (
    select
      count(*)::int as total,
      round(avg(score)::numeric, 1) as avg_rating
    from target_reviews
  )
  select
    (select count(*)::int from mutual_dedup) as mutual_connection_count,
    coalesce((select array_agg(other_id) from mutual_top), array[]::uuid[]) as mutual_top_user_ids,
    -- Threshold: hide the average until we have ≥3 reviews, otherwise
    -- a single rating dominates and is meaningless.
    case when rs.total >= 3 then rs.avg_rating::numeric(2,1) else null::numeric(2,1) end as avg_meeting_rating,
    rs.total as total_meeting_reviews
  from review_stats rs;
end;
$$;

revoke all on function public.get_profile_signals(uuid) from public, anon;
grant execute on function public.get_profile_signals(uuid) to authenticated;

comment on function public.get_profile_signals(uuid) is
  'Returns trust signals (mutual connection count + top 5 mutual ids, avg meeting review rating, total review count) for a profile. Hidden for self-view and for blocked pairs. Average rating intentionally hidden when < 3 reviews to suppress noise from a single skewed rating. Outcome enum (useful/not_useful/no_show) is mapped to 5/2/1 for the average.';
