-- Lookup an account's email by its public handle.
-- Used by the sign-in form to support handle-based password sign-in
-- (Supabase Auth only authenticates by email, so the client resolves
-- the handle to an email and then calls signInWithPassword).
--
-- Grants to anon are required because the caller is unauthenticated
-- at sign-in time. Handles are already public profile identifiers
-- (used in /p/<handle> URLs), so leaking handle → email is a
-- conscious trade-off for the username login UX.

create or replace function public.lookup_email_by_handle(p_handle text)
returns text
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_email text;
begin
  if p_handle is null or trim(p_handle) = '' then
    return null;
  end if;
  select u.email::text
    into v_email
    from public.profiles p
    join auth.users u on u.id = p.id
   where lower(p.handle::text) = lower(trim(p_handle));
  return v_email;
end;
$$;

grant execute on function public.lookup_email_by_handle(text) to anon, authenticated;
