-- Chat polish: enable full UPDATE realtime payloads + a single overview RPC
-- that collapses the N+1 query that the chats list currently issues per row.
--
-- Notes:
--   * `replica identity full` is required for the messages UPDATE realtime
--     payload to carry every column (default replica identity only sends
--     PK + changed cols, leaving the client to merge against undefined).
--   * `list_conversation_overview` is SECURITY DEFINER; it asserts the caller
--     matches `p_user_id` (defaulting to `auth.uid()`) so the function can be
--     run via PostgREST while remaining testable with an explicit user arg.
--   * Indexes relied upon by the function body:
--       conversations_a_last_msg_idx / conversations_b_last_msg_idx
--         — drive the participant-or filter + ORDER BY last_message_at DESC.
--       messages_conversation_created_idx (conversation_id, created_at)
--         — drives the "last message" lateral subquery (ORDER BY created_at DESC LIMIT 1).
--       conversation_reads PK (user_id, conversation_id) — covers the last_read_at lookup.
--       conversation_mutes PK (user_id, conversation_id) — covers the mute exists() check.
--   * Return shape returns last_message_body + last_message_kind separately so
--     the client can format previews (e.g. "📷 Photo") in the user's locale
--     via i18n instead of baking copy into the database.

alter table public.messages replica identity full;

create or replace function public.list_conversation_overview(
  p_user_id uuid default auth.uid()
)
returns table (
  conversation_id    uuid,
  peer_id            uuid,
  peer_name          text,
  peer_handle        text,
  peer_photo_url     text,
  last_message_body  text,
  last_message_kind  public.message_kind,
  last_message_at    timestamptz,
  unread_count       integer,
  is_muted           boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;
  if p_user_id <> auth.uid() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return query
  with my_convos as (
    select c.id,
           c.last_message_at,
           case
             when c.participant_a_id = p_user_id then c.participant_b_id
             else c.participant_a_id
           end as peer_id
      from public.conversations c
     where c.participant_a_id = p_user_id
        or c.participant_b_id = p_user_id
  )
  select
    mc.id as conversation_id,
    mc.peer_id,
    p.name              as peer_name,
    p.handle::text      as peer_handle,
    p.photo_url         as peer_photo_url,
    lm.body             as last_message_body,
    lm.kind             as last_message_kind,
    mc.last_message_at,
    coalesce((
      select count(*)::integer
        from public.messages m
       where m.conversation_id = mc.id
         and m.sender_id is not null
         and m.sender_id <> p_user_id
         and m.deleted_at is null
         and m.created_at > coalesce(
           (select last_read_at from public.conversation_reads cr
              where cr.user_id = p_user_id and cr.conversation_id = mc.id),
           '1970-01-01'::timestamptz
         )
    ), 0) as unread_count,
    exists(
      select 1 from public.conversation_mutes cm
       where cm.user_id = p_user_id and cm.conversation_id = mc.id
    ) as is_muted
  from my_convos mc
  left join public.profiles p
    on p.id = mc.peer_id
  left join lateral (
    select m.body, m.kind
      from public.messages m
     where m.conversation_id = mc.id
       and m.deleted_at is null
     order by m.created_at desc
     limit 1
  ) lm on true
  order by mc.last_message_at desc nulls last;
end;
$$;

grant execute on function public.list_conversation_overview(uuid) to authenticated;
