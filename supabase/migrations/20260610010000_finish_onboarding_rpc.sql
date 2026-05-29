-- Atomic onboarding completion: write the wizard's payload and flip
-- onboarded=true in a single SECURITY DEFINER call.
--
-- Background: migration 20260606000000_rls_hardening.sql revokes UPDATE on
-- the onboarded column from authenticated, so a client-side
-- `from('profiles').update({...,'onboarded':true})` raises 42501.
-- The wizard now calls this RPC instead so the column write succeeds under
-- the definer's privileges while the profiles_onboarded_completeness
-- constraint still enforces that every required field is set before the
-- flip lands.

create or replace function public.finish_onboarding(
  p_name         text,
  p_handle       text,
  p_headline     text,
  p_bio          text,
  p_roles        text[],
  p_primary_role text,
  p_city         text,
  p_country      text,
  p_goal_type    public.goal_type,
  p_goal_text    text
)
returns public.profiles
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_caller uuid := auth.uid();
  v_row    public.profiles;
begin
  if v_caller is null then
    raise exception 'unauthenticated' using errcode='28000';
  end if;

  -- The wire payload is text[]; cast into the role_kind[] column type. An
  -- empty array stays valid; bad enum values raise 22P02 and surface as a
  -- ValidationException on the client.
  update public.profiles
     set name         = p_name,
         handle       = p_handle,
         headline     = nullif(p_headline, ''),
         bio          = nullif(p_bio, ''),
         roles        = coalesce(p_roles, '{}'::text[])::public.role_kind[],
         primary_role = case
                          when p_primary_role is null then null
                          else p_primary_role::public.role_kind
                        end,
         city         = p_city,
         country      = p_country,
         goal_type    = p_goal_type,
         goal_text    = p_goal_text,
         onboarded    = true
   where id = v_caller
  returning * into v_row;

  if v_row.id is null then
    raise exception 'profile row missing for %', v_caller using errcode='P0002';
  end if;

  return v_row;
end;
$$;

grant execute on function public.finish_onboarding(
  text, text, text, text, text[], text, text, text, public.goal_type, text
) to authenticated;
