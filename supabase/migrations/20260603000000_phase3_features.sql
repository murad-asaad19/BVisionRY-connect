-- Phase 3: private mode, public profile RPC, voice transcript pipeline, read-receipts/public-investor toggles.

-- Columns
alter table public.profiles
  add column private_mode               boolean not null default false,
  add column read_receipts_enabled      boolean not null default false,
  add column public_investor_page       boolean not null default false;

alter table public.messages
  add column transcript                 text,
  add column transcript_status          text;

-- RPCs

create or replace function public.set_private_mode(p_value boolean)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  update public.profiles set private_mode = coalesce(p_value, false) where id = v_user;
end;
$$;
grant execute on function public.set_private_mode(boolean) to authenticated;

-- Public profile RPC. Anon-callable.
create or replace function public.get_public_profile(p_handle text)
returns table (
  id uuid,
  handle text,
  name text,
  photo_url text,
  headline text,
  bio text,
  primary_role public.role_kind,
  roles public.role_kind[],
  city text,
  country text,
  verified_github_username text
)
language plpgsql stable security definer set search_path = public, extensions
as $$
begin
  if p_handle is null or length(trim(p_handle)) = 0 then
    raise exception 'handle required' using errcode='22023';
  end if;
  return query
  select p.id, p.handle::text, p.name, p.photo_url, p.headline, p.bio,
         p.primary_role, p.roles, p.city, p.country,
         case when p.public_investor_page then p.verified_github_username else null end
  from public.profiles p
  where lower(p.handle::text) = lower(trim(p_handle))
    and p.onboarded = true
    and not p.private_mode;
end;
$$;
grant execute on function public.get_public_profile(text) to anon, authenticated;

-- Update get_daily_matches to exclude private_mode profiles
create or replace function public.get_daily_matches(p_for_date date default current_date)
returns setof public.daily_matches
language plpgsql security definer set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing int;
begin
  if v_user_id is null then raise exception 'not authenticated'; end if;
  select count(*) into v_existing
  from public.daily_matches
  where user_id = v_user_id and for_date_local = p_for_date;
  if v_existing = 0 then
    insert into public.daily_matches (user_id, pick_user_id, for_date_local, match_reason)
    select v_user_id, p.id, p_for_date, public.match_reason_for(v_user_id, p.id)
    from public.profiles p
    where p.onboarded = true
      and p.id <> v_user_id
      and not p.private_mode
      and not exists (
        select 1 from public.blocks
        where (blocker_id = v_user_id and blocked_id = p.id)
           or (blocker_id = p.id and blocked_id = v_user_id)
      )
    order by public.match_score(v_user_id, p.id) desc, p.created_at desc, random()
    limit 5
    on conflict (user_id, pick_user_id, for_date_local) do nothing;
  end if;
  return query select * from public.daily_matches
    where user_id = v_user_id and for_date_local = p_for_date
    order by created_at;
end;
$$;

-- Update search_discoverable_profiles to exclude private_mode
create or replace function public.search_discoverable_profiles(
  p_query text default null,
  p_roles public.role_kind[] default null,
  p_goal_types public.goal_type[] default null,
  p_country text default null,
  p_cursor timestamptz default '9999-12-31'::timestamptz,
  p_limit int default 20
)
returns table (
  id uuid, handle text, name text, photo_url text, headline text, bio text,
  roles public.role_kind[], primary_role public.role_kind, city text, country text,
  goal_type public.goal_type, goal_text text, created_at timestamptz
)
language plpgsql stable security definer set search_path = public, extensions
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  return query
  select p.id, p.handle::text, p.name, p.photo_url, p.headline, p.bio,
         p.roles, p.primary_role, p.city, p.country, p.goal_type, p.goal_text, p.created_at
  from public.profiles p
  where p.onboarded = true and p.id <> v_user
    and not p.private_mode
    and p.created_at < p_cursor
    and not exists (
      select 1 from public.blocks
      where (blocker_id = v_user and blocked_id = p.id)
         or (blocker_id = p.id and blocked_id = v_user)
    )
    and (p_query is null or trim(p_query) = ''
         or p.handle::text ilike '%' || p_query || '%'
         or coalesce(p.name, '') ilike '%' || p_query || '%')
    and (p_roles is null or cardinality(p_roles) = 0
         or exists (select 1 from unnest(p.roles) a join unnest(p_roles) b on a = b))
    and (p_goal_types is null or cardinality(p_goal_types) = 0 or p.goal_type = any(p_goal_types))
    and (p_country is null or trim(p_country) = '' or lower(p.country) = lower(p_country))
  order by p.created_at desc
  limit p_limit;
end;
$$;

-- Voice transcription dispatcher
create or replace function public.dispatch_transcription(p_message_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare v_url text := 'http://kong:8000/functions/v1/transcribe-voice';
begin
  update public.messages set transcript_status = 'pending'
  where id = p_message_id and transcript_status is null;
  begin
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := jsonb_build_object('message_id', p_message_id)
    );
  exception when others then
    update public.messages
    set transcript_status = 'failed', transcript = SQLERRM
    where id = p_message_id;
  end;
end;
$$;

-- Trigger: on voice message insert, dispatch transcription
create or replace function public.on_voice_message_inserted()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.kind = 'voice'::public.message_kind and new.media_path is not null then
    perform public.dispatch_transcription(new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists messages_voice_transcribe on public.messages;
create trigger messages_voice_transcribe
  after insert on public.messages
  for each row execute function public.on_voice_message_inserted();
