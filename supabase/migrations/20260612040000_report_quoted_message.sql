-- Report quoted-message linkage: close the report_target client/DB contract gap.
--
-- Why this migration exists:
--   The Flutter chat client reports an offending *message* by passing the
--   source message id to PrivacyService.reportTarget(...), which forwards it as
--   the RPC param `p_quoted_message_id` (lib/features/privacy/data/
--   privacy_service.dart). The live report_target(text,uuid,text,text) has only
--   four params and no place to store it, so every message report 404'd at
--   PostgREST (PGRST202: no function matches that argument signature) — the
--   feature was wired end-to-end in the UI but dead at the DB boundary.
--
--   Fix (two idempotent blocks):
--     1. reports: add nullable quoted_message_id uuid, FK -> messages(id)
--        ON DELETE SET NULL. The link is moderation context, not the report's
--        subject, so a deleted message must not cascade-delete the report;
--        SET NULL keeps the report row, dropping only the dangling pointer.
--        Meaningful only for target_type = 'message'; null for profile/intro.
--     2. report_target: re-issue with a 5th param
--        `p_quoted_message_id uuid default null` and persist it. DROP-then-
--        CREATE (not CREATE OR REPLACE) because adding a parameter changes the
--        function's argument-type signature — replace-in-place would instead
--        leave the old 4-arg overload in place alongside the new one. Every
--        existing guard (auth check, self-report block, daily dedup ON
--        CONFLICT) is preserved verbatim. The default keeps non-chat callers
--        (profile / intro reports) calling with four args unaffected, and the
--        recreate restores the default PUBLIC EXECUTE grant identically, so no
--        explicit re-grant is required.

-- ============================================================
-- 1. reports: quoted_message_id column
-- ============================================================
alter table public.reports
  add column if not exists quoted_message_id uuid
  references public.messages(id) on delete set null;

comment on column public.reports.quoted_message_id is
  'Optional FK to the reported message (target_type = message). ON DELETE SET '
  'NULL: keep the report, drop the link if the message is later deleted.';

-- Covering index for the FK. The reports table already indexes its other two
-- FKs (reporter_id leads the unique dedup index; target_id has its own), so
-- this keeps the convention AND — more importantly — makes the ON DELETE SET
-- NULL referencing lookup an index scan instead of a seq scan of reports on
-- every message deletion. Partial (the column is null for profile/intro
-- reports) keeps it small; the FK lookup only ever probes non-null values.
create index if not exists reports_quoted_message_idx
  on public.reports (quoted_message_id)
  where quoted_message_id is not null;

-- ============================================================
-- 2. report_target: add p_quoted_message_id, persist it
--    DROP first (signature change), then recreate with all guards intact.
-- ============================================================
drop function if exists public.report_target(text, uuid, text, text);
create or replace function public.report_target(
  p_target_type text,
  p_target_id uuid,
  p_reason text,
  p_note text,
  p_quoted_message_id uuid default null
)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'unauthenticated' using errcode='28000'; end if;
  if p_target_type = 'profile' and p_target_id = v_user then
    raise exception 'cannot report self' using errcode='22023';
  end if;
  insert into public.reports (reporter_id, target_type, target_id, reason, note, quoted_message_id)
  values (
    v_user,
    p_target_type::public.report_target_type,
    p_target_id,
    p_reason::public.report_reason,
    p_note,
    p_quoted_message_id
  )
  on conflict (reporter_id, target_type, target_id, (timezone('UTC', created_at)::date))
  do nothing;
end;
$function$;
