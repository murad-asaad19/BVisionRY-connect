-- Opportunities — post-review fixes (part 2 of 2).
--
-- This sibling migration redefines notify_opportunity_interest now that
-- 'opportunity_interest' has been committed to the notification_kind enum
-- in 20260608050000_opportunities_fixes.sql. Postgres forbids using a
-- newly-added enum value within the same transaction it is added, so the
-- trigger swap lives here.
--
-- Findings addressed
-- ------------------
--   #11 Trigger now consults should_notify(...) against the new
--       'opportunity_interest' kind. The pre-existing default-on
--       behaviour of should_notify (no row in notification_preferences
--       means enabled) preserves current behaviour for everyone who has
--       not explicitly opted out; an opt-out toggle is a UI-only follow-up.
--
--   #12 push_log's unique key (event_table, event_id, recipient_id)
--       collided for every interest on the same opportunity, because
--       notify_opportunity_interest passed new.opportunity_id as the
--       event_id. Only the FIRST interest ever produced a push. We now
--       synthesize a deterministic per-interest event_id from
--       md5(opportunity_id || ':' || user_id)::uuid so every interest
--       maps to a distinct push_log row while still being replay-safe
--       against accidental double-fires of the trigger.

create or replace function public.notify_opportunity_interest()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_author     uuid;
  v_title      text;
  v_from_name  text;
  v_event_id   uuid;
begin
  select o.author_id, o.title into v_author, v_title
    from public.opportunities o
   where o.id = new.opportunity_id;
  if v_author is null or v_author = new.user_id then
    return new;
  end if;

  -- Preference gate. should_notify() is default-on for users with no row
  -- (see 20260604000000_audit_fixes.sql), so existing users see no
  -- behavioural change; explicit opt-out is now possible via the
  -- 'opportunity_interest' kind that was added in the sibling migration.
  if not public.should_notify(
       v_author,
       'opportunity_interest'::public.notification_kind,
       'push'::public.notification_channel
     ) then
    return new;
  end if;

  select name into v_from_name from public.profiles where id = new.user_id;

  -- Deterministic per-interest event_id. Previously we passed
  -- new.opportunity_id, which collided in push_log under its
  -- (event_table, event_id, recipient_id) unique key — meaning only the
  -- FIRST interest on an opportunity ever produced a push. md5(opp || user)
  -- gives us one row per interest while staying idempotent against
  -- accidental double-fires of the trigger.
  v_event_id := md5(new.opportunity_id::text || ':' || new.user_id::text)::uuid;

  perform public.dispatch_push(
    v_author,
    'opportunity_interests',
    v_event_id,
    jsonb_build_object(
      'kind',                'opportunity_interest',
      'title',               'New interest in ' || coalesce(v_title, 'your opportunity'),
      'body',                coalesce(v_from_name, 'Someone') || ' is interested.',
      'url',                 '/(app)/opportunities/' || new.opportunity_id,
      'opportunity_id',      new.opportunity_id,
      'opportunity_title',   v_title,
      'from_user_id',        new.user_id,
      'from_user_name',      v_from_name
    ),
    p_kind            => 'opportunity_interest',
    p_entity_id       => new.opportunity_id,
    p_conversation_id => null
  );
  return new;
end;
$$;
