-- pgTAP: lookup_email_by_handle execute grants after the revoke migration.
--
-- Under test:
--   * 20260606060000_revoke_handle_lookup.sql — execute revoked from anon,
--     but the function is intentionally kept callable by service_role for
--     internal/legacy use. authenticated grant from earlier migrations was
--     also kept by that file (only anon was revoked).
--
-- Rather than trying to actually call the function as anon (which would
-- require connecting via PostgREST), we inspect the catalog grants directly.

begin;
select plan(2);

-- =============================================================================
-- 1. anon role must NOT have EXECUTE on public.lookup_email_by_handle(text).
-- =============================================================================
select is(
  has_function_privilege(
    'anon',
    'public.lookup_email_by_handle(text)',
    'EXECUTE'
  ),
  false,
  'anon has NO execute on lookup_email_by_handle(text) after revoke migration'
);

-- =============================================================================
-- 2. service_role must STILL have EXECUTE on the same function — used for
--    internal/legacy callers per the migration's deprecation comment.
-- =============================================================================
select is(
  has_function_privilege(
    'service_role',
    'public.lookup_email_by_handle(text)',
    'EXECUTE'
  ),
  true,
  'service_role still has execute on lookup_email_by_handle(text)'
);

select * from finish();
rollback;
