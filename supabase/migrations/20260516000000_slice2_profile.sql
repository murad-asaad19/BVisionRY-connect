-- Slice 2: extend profiles with the core fieldset, add enums, RPC, completeness check.

create extension if not exists citext with schema extensions;

create type public.role_kind as enum ('founder', 'leader', 'builder', 'investor');
create type public.goal_type as enum (
  'hire', 'be_hired', 'co_found', 'invest', 'take_investment',
  'advise', 'find_advisor', 'peer_connect'
);

alter table public.profiles
  add column handle           extensions.citext,
  add column name             text,
  add column headline         text,
  add column bio              text,
  add column roles            public.role_kind[] not null default '{}'::public.role_kind[],
  add column primary_role     public.role_kind,
  add column city             text,
  add column country          text,
  add column goal_type        public.goal_type,
  add column goal_text        text,
  add column goal_updated_at  timestamptz,
  add column photo_url        text,
  add column onboarded        boolean not null default false;

alter table public.profiles
  add constraint profiles_handle_unique unique (handle),
  add constraint profiles_handle_format check (
    handle is null or (handle operator(extensions.~)
      '^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$'::extensions.citext)
  ),
  add constraint profiles_name_len check (
    name is null or (char_length(name) between 1 and 80)
  ),
  add constraint profiles_headline_len check (
    headline is null or (char_length(headline) between 5 and 120)
  ),
  add constraint profiles_bio_len check (
    bio is null or (char_length(bio) between 10 and 1000)
  ),
  add constraint profiles_goal_text_len check (
    goal_text is null or (char_length(goal_text) between 10 and 280)
  ),
  add constraint profiles_primary_role_in_roles check (
    primary_role is null or primary_role = any (roles)
  ),
  add constraint profiles_onboarded_completeness check (
    not onboarded or (
      handle is not null
      and name is not null
      and cardinality(roles) >= 1
      and primary_role is not null
      and goal_type is not null
      and goal_text is not null
      and city is not null
      and country is not null
    )
  );

create index profiles_primary_role_idx on public.profiles (primary_role) where primary_role is not null;
create index profiles_onboarded_idx on public.profiles (onboarded) where onboarded = true;

create or replace function public.profiles_set_goal_updated_at()
returns trigger language plpgsql as $$
begin
  if (new.goal_type is distinct from old.goal_type)
     or (new.goal_text is distinct from old.goal_text) then
    new.goal_updated_at = now();
  end if;
  return new;
end;
$$;

create trigger profiles_goal_updated_at_trigger
  before update on public.profiles
  for each row execute function public.profiles_set_goal_updated_at();

create or replace function public.check_handle_available(p_handle text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  return not exists (
    select 1 from public.profiles
    where handle = p_handle::extensions.citext
  );
end;
$$;
grant execute on function public.check_handle_available(text) to authenticated;
