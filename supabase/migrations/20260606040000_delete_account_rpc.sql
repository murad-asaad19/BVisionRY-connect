-- delete_my_account(): SECURITY DEFINER wipe of all app-level rows for auth.uid().
--
-- The edge function `delete-account` calls this RPC as the user (so auth.uid()
-- is set), then admin-deletes the auth.users row. Both steps are idempotent —
-- DELETEs over no rows are no-ops, and the auth-delete treats "not found" as
-- success. Tables with `on delete cascade` from profiles(id) would clean up
-- when auth.users is deleted, but several FK columns are `on delete set null`
-- (intros.sender_id, intros.recipient_id, messages.sender_id,
-- meeting_proposals.proposed_by_id) — so we explicitly delete those rows here
-- to truly wipe the user's footprint.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  -- Rows whose FK is `on delete set null` — delete explicitly so they don't
  -- linger as orphans after the auth.users delete.
  delete from public.intros
   where sender_id = v_user or recipient_id = v_user;

  delete from public.meeting_proposals
   where proposed_by_id = v_user;

  -- Conversations the user participates in. messages, conversation_reads,
  -- conversation_mutes, meeting_proposals(conv_id), meeting_feedback,
  -- meeting_reviews all cascade off conversations or meeting_proposals.
  delete from public.conversations
   where participant_a_id = v_user or participant_b_id = v_user;

  -- Direct user-keyed tables. Most cascade from profiles, but deleting
  -- them up-front makes this RPC self-sufficient (and idempotent) and
  -- lets us return cleanly even if the auth-delete step is skipped.
  delete from public.messages              where sender_id   = v_user;
  delete from public.push_log              where recipient_id = v_user;
  delete from public.device_tokens         where user_id      = v_user;
  delete from public.conversation_reads    where user_id      = v_user;
  delete from public.conversation_mutes    where user_id      = v_user;
  delete from public.blocks                where blocker_id   = v_user or blocked_id = v_user;
  delete from public.reports               where reporter_id  = v_user;
  delete from public.notification_preferences where user_id   = v_user;
  delete from public.meeting_feedback      where rater_id     = v_user;
  delete from public.meeting_reviews       where reviewer_id  = v_user;
  delete from public.daily_matches         where user_id      = v_user or pick_user_id = v_user;

  -- profiles row cascades from auth.users when the edge function deletes the
  -- user, but again — delete here so the RPC is self-contained.
  delete from public.profiles where id = v_user;
end;
$$;

grant execute on function public.delete_my_account() to authenticated;
