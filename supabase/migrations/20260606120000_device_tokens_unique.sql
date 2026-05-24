-- device_tokens: token must be globally unique (FCM token is device-unique).
-- On conflict, reassign the row to the new user and reactivate it. This handles
-- (a) the same device switching user accounts and (b) tokens that were revoked
-- (e.g., on sign-out) being re-registered when the same user signs back in.
--
-- Drops the older composite unique(user_id, token) because it becomes redundant
-- once token alone is unique. Cleans up duplicate tokens (older copies removed,
-- newest copy kept) before adding the constraint so the ALTER doesn't fail.

-- 1) De-duplicate: keep the newest row per token, drop older copies.
delete from public.device_tokens dt
where exists (
  select 1 from public.device_tokens older
  where older.token = dt.token
    and older.created_at < dt.created_at
);

-- 2) Drop the composite unique(user_id, token) constraint if present (default name
-- assigned by Postgres when the slice8 migration declared it inline on the table).
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'device_tokens_user_id_token_key'
  ) then
    alter table public.device_tokens
      drop constraint device_tokens_user_id_token_key;
  end if;
end $$;

-- 3) Add the unique(token) constraint if it isn't already there.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'device_tokens_token_key'
  ) then
    alter table public.device_tokens
      add constraint device_tokens_token_key unique (token);
  end if;
end $$;

-- 4) Rewrite register_device_token to upsert on token, reassign owner, and
-- reactivate revoked rows. Also refreshes platform + last_seen_at.
create or replace function public.register_device_token(
  p_token text,
  p_platform public.device_platform
)
returns public.device_tokens
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row public.device_tokens;
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_token is null or length(p_token) < 16 then
    raise exception 'invalid token' using errcode = '22023';
  end if;

  insert into public.device_tokens (user_id, token, platform)
  values (v_user, p_token, p_platform)
  on conflict (token) do update
    set user_id      = excluded.user_id,
        platform     = excluded.platform,
        last_seen_at = now(),
        revoked_at   = null
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.register_device_token(text, public.device_platform)
  to authenticated;
