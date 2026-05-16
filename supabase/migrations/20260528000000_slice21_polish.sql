-- is_mutual_match: both users have each other in today's daily_matches
create or replace function public.is_mutual_match(p_other uuid)
returns boolean
language plpgsql stable
security definer
set search_path = public
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then return false; end if;
  return exists (
    select 1 from public.daily_matches
    where user_id = v_user and pick_user_id = p_other
      and for_date_local = current_date
  ) and exists (
    select 1 from public.daily_matches
    where user_id = p_other and pick_user_id = v_user
      and for_date_local = current_date
  );
end;
$$;
grant execute on function public.is_mutual_match(uuid) to authenticated;
