-- Revoke anon access to the handle → email lookup RPC.
--
-- The handle → email mapping is no longer exposed to anon clients. Sign-in
-- by @handle now goes through the auth-handle-login edge function (which
-- holds the service-role key and bundles private_mode / suspended_at /
-- onboarded gating into the lookup so account state can't be enumerated).
--
-- The function definition is kept so service_role internal callers (and
-- any forgotten direct usage) keep working through the migration period.
-- It can be dropped in a follow-up after we confirm no service-side
-- callers remain.

revoke execute on function public.lookup_email_by_handle(text) from anon;

comment on function public.lookup_email_by_handle(text) is
  'DEPRECATED 2026-06-06: anon EXECUTE revoked. Use the auth-handle-login edge function for handle-based sign-in. Kept callable by service_role for internal use; safe to drop once no callers remain.';
