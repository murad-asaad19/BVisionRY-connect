-- Product-event funnel analytics (launch review priority #4, SQL half)
--
-- Goal: measure the core loop WITHOUT any new client tracking, by aggregating
-- tables that already exist (profiles, intros, conversations, messages,
-- meeting_proposals, meeting_reviews).
--
-- ACCESS-CONTROL DECISION (important):
--   These views aggregate org-wide data across ALL users, so they must NOT be
--   reachable by end users. We deliberately put them in a dedicated `analytics`
--   schema rather than `public`:
--     * PostgREST only exposes the schemas in its `db-schemas` setting
--       (default: public, graphql_public). The `analytics` schema is therefore
--       NOT reachable by the anon/authenticated REST roles at all.
--     * We additionally REVOKE everything from public/anon/authenticated and
--       GRANT USAGE + SELECT only to `service_role` (used by trusted server /
--       BI jobs) so even a future schema-exposure change can't leak them.
--     * Views are created WITHOUT security_invoker (the default), so they read
--       with the owner's (postgres) privileges and bypass per-user RLS — which
--       is what an org-wide funnel needs, and is safe precisely because only
--       service_role can call them.
--   If a human-facing dashboard is later needed for non-service callers, expose
--   a narrow SECURITY DEFINER function gated on a specific admin claim rather
--   than widening these views.
--
-- TIMESTAMP NOTES (grounded in the live schema, not assumed):
--   * intros has created_at + updated_at + declined_at, but NO dedicated
--     accepted_at/connected_at. The accept/connect transition is therefore
--     proxied by updated_at for rows whose state is 'accepted' or 'connected'.
--     "Accepted" in this funnel = state in ('accepted','connected') because
--     'connected' is the terminal post-accept state (an accepted intro that
--     opened a conversation), so both count as "an intro the user got
--     accepted".
--   * meeting_proposals.state is enum meeting_state
--     ('proposed','confirmed','declined','cancelled'); a booked/confirmed
--     meeting = state 'confirmed'.
--   * meeting_reviews links to a proposal via meeting_id = meeting_proposals.id.
--   * A "2-way conversation" = a conversation with >=1 message from BOTH
--     participants (participant_a_id and participant_b_id).
--   * "Onboarded user" = profiles.onboarded = true.

create schema if not exists analytics;

-- Lock the schema down to trusted callers only.
revoke all on schema analytics from public;
grant usage on schema analytics to service_role;

-- ============================================================
-- Base helper: per-conversation two-way flag (reused by several views)
-- ============================================================
-- A conversation is "two-way" once each participant has sent >=1 message.
create or replace view analytics.v_conversation_twoway as
select
  c.id as conversation_id,
  c.participant_a_id,
  c.participant_b_id,
  c.created_at,
  bool_or(m.sender_id = c.participant_a_id) as a_spoke,
  bool_or(m.sender_id = c.participant_b_id) as b_spoke,
  (bool_or(m.sender_id = c.participant_a_id)
   and bool_or(m.sender_id = c.participant_b_id)) as is_two_way,
  min(m.created_at) as first_message_at,
  max(m.created_at) as last_message_at,
  count(m.id) as message_count
from public.conversations c
left join public.messages m
  on m.conversation_id = c.id and m.deleted_at is null
group by c.id, c.participant_a_id, c.participant_b_id, c.created_at;

-- ============================================================
-- 1. Core funnel: counts per step + step-to-step conversion %
-- ============================================================
-- Steps (each counts DISTINCT users who reached the step):
--   1 onboarded            : profiles.onboarded
--   2 sent >=1 intro       : distinct intros.sender_id
--   3 had an intro accepted: distinct sender of an intro in accepted/connected
--   4 had a 2-way convo    : distinct participant of a two-way conversation
--   5 booked a meeting     : distinct participant in a convo with a confirmed
--                            meeting_proposal
--   6 completed a review   : distinct reviewer in meeting_reviews
create or replace view analytics.v_funnel_overall as
with
onboarded as (
  select id as user_id from public.profiles where onboarded = true
),
sent_intro as (
  select distinct sender_id as user_id
  from public.intros
  where sender_id is not null
),
got_accept as (
  select distinct sender_id as user_id
  from public.intros
  where sender_id is not null
    and state in ('accepted'::public.intro_state, 'connected'::public.intro_state)
),
two_way_users as (
  select participant_a_id as user_id from analytics.v_conversation_twoway where is_two_way
  union
  select participant_b_id as user_id from analytics.v_conversation_twoway where is_two_way
),
booked_meeting_convos as (
  select distinct mp.conversation_id
  from public.meeting_proposals mp
  where mp.state = 'confirmed'::public.meeting_state
),
booked_users as (
  select c.participant_a_id as user_id
  from public.conversations c
  join booked_meeting_convos b on b.conversation_id = c.id
  union
  select c.participant_b_id
  from public.conversations c
  join booked_meeting_convos b on b.conversation_id = c.id
),
reviewed as (
  select distinct reviewer_id as user_id
  from public.meeting_reviews
  where reviewer_id is not null
),
steps(step_no, step_name, users) as (
  select 1, 'onboarded',              (select count(*) from onboarded)
  union all select 2, 'sent_intro',        (select count(*) from sent_intro)
  union all select 3, 'intro_accepted',    (select count(*) from got_accept)
  union all select 4, 'two_way_convo',     (select count(distinct user_id) from two_way_users)
  union all select 5, 'meeting_booked',    (select count(distinct user_id) from booked_users)
  union all select 6, 'review_completed',  (select count(*) from reviewed)
)
select
  step_no,
  step_name,
  users,
  lag(users) over (order by step_no) as prev_step_users,
  round(
    100.0 * users / nullif(lag(users) over (order by step_no), 0), 1
  ) as step_conversion_pct,
  round(
    100.0 * users / nullif(first_value(users) over (order by step_no), 0), 1
  ) as pct_of_top
from steps
order by step_no;

-- ============================================================
-- 2. Activation: % of new users who, within 7 days of signup,
--    (a) completed their profile AND (b) sent their first intro.
-- ============================================================
-- "Completed profile" is proxied by onboarded = true (onboarding gate).
-- created_at on profiles is the signup timestamp.
create or replace view analytics.v_activation_7d as
with base as (
  select
    p.id,
    p.created_at as signed_up_at,
    p.onboarded,
    (
      select min(i.created_at)
      from public.intros i
      where i.sender_id = p.id
    ) as first_intro_at
  from public.profiles p
)
select
  count(*) as total_users,
  count(*) filter (where onboarded) as completed_profile,
  count(*) filter (
    where onboarded
      and first_intro_at is not null
      and first_intro_at <= signed_up_at + interval '7 days'
  ) as activated_7d,
  round(
    100.0 * count(*) filter (
      where onboarded
        and first_intro_at is not null
        and first_intro_at <= signed_up_at + interval '7 days'
    ) / nullif(count(*), 0), 1
  ) as activation_rate_pct
from base;

-- ============================================================
-- 3. Core-loop health: accept-rate, median time sent->accepted,
--    % of accepted intros that produce >=1 reply.
-- ============================================================
-- accept-rate = (accepted or connected) / total intros.
-- time-to-accept proxied by (updated_at - created_at) on accepted/connected
--   intros (no accepted_at column exists).
-- "produces >=1 reply": the intro's conversation is two-way (both peers spoke).
--   Linked via intros.conversation_id.
create or replace view analytics.v_core_loop_health as
with intros_base as (
  select
    i.id,
    i.state,
    i.created_at,
    i.updated_at,
    i.conversation_id,
    (i.state in ('accepted'::public.intro_state, 'connected'::public.intro_state)) as is_accepted
  from public.intros i
)
select
  count(*) as total_intros,
  count(*) filter (where is_accepted) as accepted_intros,
  round(100.0 * count(*) filter (where is_accepted) / nullif(count(*), 0), 1) as accept_rate_pct,
  -- median sent->accepted latency over accepted intros (proxy via updated_at)
  (
    select percentile_cont(0.5) within group (order by extract(epoch from (ib.updated_at - ib.created_at)))
    from intros_base ib
    where ib.is_accepted
  ) as median_secs_sent_to_accepted,
  -- % of accepted intros whose conversation became two-way (>=1 reply each side)
  round(
    100.0 * count(*) filter (
      where is_accepted
        and conversation_id in (select conversation_id from analytics.v_conversation_twoway where is_two_way)
    ) / nullif(count(*) filter (where is_accepted), 0), 1
  ) as accepted_with_reply_pct
from intros_base;

-- ============================================================
-- 4. Retention: weekly signup cohort, % active in week N.
-- ============================================================
-- A user is "active" in a calendar week if they SENT an intro OR sent a
-- message that week. week_offset 0 = signup week. Activity is keyed to the
-- user's signup week so week N is relative, not absolute.
create or replace view analytics.v_retention_weekly as
with users as (
  select id, date_trunc('week', created_at) as cohort_week
  from public.profiles
),
activity as (
  select sender_id as user_id, date_trunc('week', created_at) as active_week
  from public.intros
  where sender_id is not null
  union all
  select sender_id, date_trunc('week', created_at)
  from public.messages
  where sender_id is not null
),
cohort_activity as (
  select
    u.cohort_week,
    u.id as user_id,
    (extract(epoch from (a.active_week - u.cohort_week)) / (7*24*3600))::int as week_offset
  from users u
  join activity a on a.user_id = u.id
  where a.active_week >= u.cohort_week
  group by u.cohort_week, u.id, a.active_week
),
cohort_size as (
  select cohort_week, count(*) as cohort_users
  from users group by cohort_week
)
select
  cs.cohort_week,
  cs.cohort_users,
  ca.week_offset,
  count(distinct ca.user_id) as active_users,
  round(100.0 * count(distinct ca.user_id) / nullif(cs.cohort_users, 0), 1) as retention_pct
from cohort_size cs
left join cohort_activity ca on ca.cohort_week = cs.cohort_week
group by cs.cohort_week, cs.cohort_users, ca.week_offset
order by cs.cohort_week, ca.week_offset nulls last;

-- ============================================================
-- 5. Liquidity / density: daily intros sent/accepted, active senders.
-- ============================================================
-- Marketplace health by UTC calendar day. accepted_on_day uses updated_at as
-- the accept-day proxy for accepted/connected intros.
create or replace view analytics.v_liquidity_daily as
with sent as (
  select (created_at at time zone 'UTC')::date as day,
         count(*) as intros_sent,
         count(distinct sender_id) as active_senders
  from public.intros
  group by 1
),
accepted as (
  select (updated_at at time zone 'UTC')::date as day,
         count(*) as intros_accepted
  from public.intros
  where state in ('accepted'::public.intro_state, 'connected'::public.intro_state)
  group by 1
)
select
  coalesce(s.day, a.day) as day,
  coalesce(s.intros_sent, 0) as intros_sent,
  coalesce(s.active_senders, 0) as active_senders,
  coalesce(a.intros_accepted, 0) as intros_accepted
from sent s
full outer join accepted a on a.day = s.day
order by day;

-- ============================================================
-- Grants: read-only, service_role only.
-- ============================================================
grant select on all tables in schema analytics to service_role;
-- (views are "tables" for grant purposes). Default future objects too:
alter default privileges in schema analytics grant select on tables to service_role;
