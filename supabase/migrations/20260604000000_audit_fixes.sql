-- Audit fixes pass:
--   * profiles.suspended_at for I5 suspended screen
--   * meeting_reviews.rating int → outcome text ('useful' | 'not_useful' | 'no_show')
--   * notification_preferences (per kind × channel) + helper + trigger updates

-- ───────────────────── profiles.suspended_at ─────────────────────
alter table public.profiles
  add column if not exists suspended_at timestamptz;

-- ───────────── meeting_reviews: outcome-based reviews ────────────
-- 1) drop the int rating check, add outcome text, drop rating
alter table public.meeting_reviews
  drop constraint if exists meeting_reviews_rating_check;

alter table public.meeting_reviews
  add column if not exists outcome text;

-- Backfill any existing rows from rating → outcome heuristic
update public.meeting_reviews
   set outcome = case
     when rating >= 4 then 'useful'
     when rating = 1 then 'no_show'
     else 'not_useful'
   end
 where outcome is null and rating is not null;

alter table public.meeting_reviews
  drop column if exists rating;

alter table public.meeting_reviews
  alter column outcome set not null;

alter table public.meeting_reviews
  add constraint meeting_reviews_outcome_chk
    check (outcome in ('useful', 'not_useful', 'no_show'));

-- 2) drop+recreate submit_meeting_review with new signature
drop function if exists public.submit_meeting_review(uuid, int, text);

create or replace function public.submit_meeting_review(
  p_meeting_id uuid,
  p_outcome    text,
  p_note       text
) returns public.meeting_reviews
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row  public.meeting_reviews;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_outcome not in ('useful', 'not_useful', 'no_show') then
    raise exception 'outcome must be useful, not_useful, or no_show' using errcode = '22023';
  end if;
  insert into public.meeting_reviews (meeting_id, reviewer_id, outcome, note)
  values (p_meeting_id, v_user, p_outcome, nullif(trim(coalesce(p_note, '')), ''))
  on conflict (meeting_id, reviewer_id) do update
    set outcome = excluded.outcome,
        note    = excluded.note
  returning * into v_row;
  return v_row;
end;
$$;

grant execute on function public.submit_meeting_review(uuid, text, text) to authenticated;

-- ────────── notification_preferences (per kind × channel) ────────
create type public.notification_kind as enum (
  'intro_received',
  'intro_accepted',
  'message_received',
  'voice_received',
  'meeting_reminder',
  'daily_matches_ready',
  'goal_staleness'
);

create type public.notification_channel as enum ('push', 'email', 'in_app');

create table public.notification_preferences (
  user_id  uuid not null references public.profiles(id) on delete cascade,
  kind     public.notification_kind not null,
  channel  public.notification_channel not null,
  enabled  boolean not null default true,
  primary key (user_id, kind, channel)
);

alter table public.notification_preferences enable row level security;

create policy notification_prefs_select_own on public.notification_preferences
  for select using (user_id = auth.uid());
create policy notification_prefs_modify_own on public.notification_preferences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Helper: default-on if row missing
create or replace function public.should_notify(
  p_user_id uuid,
  p_kind    public.notification_kind,
  p_channel public.notification_channel
) returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce(
    (select enabled from public.notification_preferences
       where user_id = p_user_id and kind = p_kind and channel = p_channel),
    true
  );
$$;
grant execute on function public.should_notify(uuid, public.notification_kind, public.notification_channel) to authenticated;

-- Update notify_intro_inserted to consult per-channel prefs (push only relevant here)
create or replace function public.notify_intro_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.state = 'delivered' and new.recipient_id is not null then
    if public.should_notify(new.recipient_id, 'intro_received'::public.notification_kind, 'push'::public.notification_channel) then
      perform public.dispatch_push(
        new.recipient_id, 'intros', new.id,
        jsonb_build_object(
          'kind','intro_received','title','New intro','body','You have a new intro to review.',
          'url','/(app)/intros/' || new.id
        )
      );
    end if;
  end if;
  return new;
end; $$;

create or replace function public.notify_message_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_recipient uuid;
  v_conv public.conversations;
  v_body text;
  v_title text;
  v_kind  public.notification_kind;
begin
  if new.sender_id is null then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := case
    when v_conv.participant_a_id = new.sender_id then v_conv.participant_b_id
    else v_conv.participant_a_id
  end;

  if new.kind = 'meeting'::public.message_kind then
    v_kind  := 'meeting_reminder'::public.notification_kind;
    v_title := 'New meeting proposal';
    v_body  := 'Tap to view the proposed times.';
  elsif new.kind = 'image'::public.message_kind then
    v_kind  := 'message_received'::public.notification_kind;
    v_title := 'New photo';
    v_body  := 'Photo';
  elsif new.kind = 'voice'::public.message_kind then
    v_kind  := 'voice_received'::public.notification_kind;
    v_title := 'New voice message';
    v_body  := 'Voice message';
  else
    v_kind  := 'message_received'::public.notification_kind;
    v_title := 'New message';
    v_body  := coalesce(left(new.body, 80), '');
  end if;

  if public.should_notify(v_recipient, v_kind, 'push'::public.notification_channel) then
    perform public.dispatch_push(
      v_recipient, 'messages', new.id,
      jsonb_build_object(
        'kind', case
          when new.kind = 'meeting'::public.message_kind then 'meeting_received'
          when new.kind = 'image'::public.message_kind then 'image_received'
          when new.kind = 'voice'::public.message_kind then 'voice_received'
          else 'message_received'
        end,
        'title', v_title, 'body', v_body,
        'url','/(app)/chats/' || new.conversation_id
      )
    );
  end if;
  return new;
end; $$;

create or replace function public.notify_meeting_confirmed()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_conv public.conversations;
  v_recipient uuid;
begin
  if old.state = new.state then return new; end if;
  if new.state <> 'confirmed'::public.meeting_state then return new; end if;
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then return new; end if;
  v_recipient := new.proposed_by_id;
  if v_recipient is null then return new; end if;
  if public.should_notify(v_recipient, 'meeting_reminder'::public.notification_kind, 'push'::public.notification_channel) then
    perform public.dispatch_push(
      v_recipient, 'meeting_proposals', new.id,
      jsonb_build_object(
        'kind','meeting_confirmed','title','Meeting confirmed',
        'body','Your meeting has been confirmed.',
        'url','/(app)/chats/' || new.conversation_id
      )
    );
  end if;
  return new;
end; $$;
