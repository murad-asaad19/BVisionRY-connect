-- Security fix: anon clients should not be able to read profiles.
--
-- The slice 9 `profiles_select_discoverable` policy did not require
-- `auth.uid() is not null`, so an unauthenticated REST call to
-- `/rest/v1/profiles` exposed every onboarded user's full row including
-- private fields (notify_intro/message/meeting, goal_text,
-- verified_github_username, verified_github_id).
--
-- All profile reads in the app go through an authenticated session, so
-- requiring authentication is consistent with actual usage.

drop policy profiles_select_discoverable on public.profiles;

create policy profiles_select_discoverable on public.profiles
  for select using (
    auth.uid() is not null
    and onboarded = true
    and not exists (
      select 1 from public.blocks
      where (blocker_id = auth.uid() and blocked_id = profiles.id)
         or (blocker_id = profiles.id and blocked_id = auth.uid())
    )
  );
