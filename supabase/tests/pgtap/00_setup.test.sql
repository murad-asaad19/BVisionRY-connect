-- Pre-test hook for the pgTAP suite.
--
-- Supabase enables pgtap on managed databases by default, but the local stack
-- does not, so we install it idempotently here. This file is named *.test.sql
-- so it sorts FIRST under the pg_prove globber and its trivial pgTAP plan keeps
-- the runner happy. The extension install itself is wrapped in a separate
-- transaction (CREATE EXTENSION can't run inside the BEGIN/ROLLBACK that
-- pgTAP expects) — that's fine because the extension is idempotent and we
-- never need to "roll back" the install.
--
-- Subsequent files (01_*.test.sql … 06_*.test.sql) follow the standard
-- BEGIN; plan(N); ... finish(); ROLLBACK; pattern.

create extension if not exists pgtap with schema extensions;

begin;
select plan(1);
select ok(true, 'pgtap suite setup complete');
select * from finish();
rollback;
