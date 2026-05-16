create or replace function public.list_connections()
returns table (
  user_id uuid,
  handle text,
  name text,
  photo_url text,
  primary_role public.role_kind,
  conversation_id uuid,
  connected_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;

  return query
  select distinct on (other_id)
    other_id as user_id,
    p.handle::text,
    p.name,
    p.photo_url,
    p.primary_role,
    i.conversation_id,
    i.updated_at as connected_at
  from (
    select case when sender_id = v_user then recipient_id else sender_id end as other_id, *
    from public.intros
    where state = 'connected'::public.intro_state
      and (sender_id = v_user or recipient_id = v_user)
      and conversation_id is not null
  ) i
  join public.profiles p on p.id = i.other_id and p.onboarded = true
  where not exists (
    select 1 from public.blocks
    where (blocker_id = v_user and blocked_id = i.other_id)
       or (blocker_id = i.other_id and blocked_id = v_user)
  )
  order by other_id, i.updated_at desc;
end;
$$;
grant execute on function public.list_connections() to authenticated;
