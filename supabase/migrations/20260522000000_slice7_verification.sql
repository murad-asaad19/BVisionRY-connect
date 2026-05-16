-- Slice 7: verification — add GitHub fields + set/clear RPCs

alter table public.profiles
  add column verified_github_username text,
  add column verified_github_id bigint,
  add column verified_at timestamptz;

create index profiles_verified_github_username_idx
  on public.profiles (verified_github_username)
  where verified_github_username is not null;

create or replace function public.set_github_verification(
  p_github_username text,
  p_github_id bigint
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row public.profiles;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if p_github_username is null or length(trim(p_github_username)) = 0 then
    raise exception 'invalid github username' using errcode='22023';
  end if;
  if p_github_id is null or p_github_id <= 0 then
    raise exception 'invalid github id' using errcode='22023';
  end if;

  update public.profiles
  set verified_github_username = lower(p_github_username),
      verified_github_id = p_github_id,
      verified_at = now()
  where id = v_user
  returning * into v_row;

  if not found then
    raise exception 'profile not found' using errcode='P0002';
  end if;

  return v_row;
end;
$$;
grant execute on function public.set_github_verification(text, bigint) to authenticated;

create or replace function public.clear_github_verification()
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_row public.profiles;
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  update public.profiles
  set verified_github_username = null,
      verified_github_id = null,
      verified_at = null
  where id = v_user
  returning * into v_row;
  return v_row;
end;
$$;
grant execute on function public.clear_github_verification() to authenticated;
