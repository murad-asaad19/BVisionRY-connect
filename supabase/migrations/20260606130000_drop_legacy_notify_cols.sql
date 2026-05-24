-- Drop legacy per-kind push opt-in booleans from `profiles`.
--
-- These columns were superseded by the `notification_preferences` table
-- (rows keyed by user_id + notification_kind + notification_channel).
-- Triggers were rewritten to read from `notification_preferences` via
-- `should_notify(...)` in 20260606030000_schema_fixes_triggers.sql; the
-- mobile settings UI now writes directly to that table via
-- `setNotificationPref()`. With no remaining readers or writers, the legacy
-- columns are safe to drop.
--
-- `if exists` keeps the migration idempotent across already-cleaned envs.

alter table public.profiles
  drop column if exists notify_intro,
  drop column if exists notify_message,
  drop column if exists notify_meeting;
