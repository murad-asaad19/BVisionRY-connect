-- Wave 5: scheduled jobs.
--
-- Enables pg_cron and registers three recurring jobs:
--   1. expire-overdue-intros        — hourly      — calls public.expire_overdue_intros()
--   2. goal-staleness-daily         — 09:00 UTC   — HTTP-POSTs the goal-staleness-reminder edge function
--   3. fcm-token-cleanup            — 03:00 UTC   — purges revoked / stale device_tokens rows
--
-- All three jobs are registered idempotently (no-op if a job of the same name
-- already exists) so re-running the migration on a populated cron.job table
-- doesn't blow up or create duplicates.
--
-- Configuration GUCs (set at the cluster level — `alter database <db> set ...`):
--   - app.functions_base_url     base URL of the edge functions (e.g. https://<ref>.functions.supabase.co)
--   - app.webhook_shared_secret  shared secret for verify_jwt=false webhook functions
--   - app.goal_staleness_secret  shared secret accepted by goal-staleness-reminder (optional;
--                                falls back to app.webhook_shared_secret if absent)
--
-- The cron jobs run as the migration superuser by default; they do NOT need a
-- separate role grant.

-- =============================================================================
-- pg_cron extension
-- =============================================================================
-- Supabase requires the extension to be allowlisted via supabase/config.toml
-- ([db.extensions] block) before `create extension` succeeds in the managed
-- environment. Local development with `supabase start` honours the same
-- allowlist. See supabase/config.toml for the corresponding block.
create extension if not exists pg_cron with schema extensions;

-- =============================================================================
-- Job 1: expire-overdue-intros (hourly)
-- =============================================================================
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'expire-overdue-intros') then
    perform cron.schedule(
      'expire-overdue-intros',
      '0 * * * *',
      $job$select public.expire_overdue_intros();$job$
    );
  end if;
end
$$;

-- =============================================================================
-- Job 2: goal-staleness-daily (09:00 UTC)
-- Uses pg_net to POST the edge function with the shared webhook secret.
-- =============================================================================
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'goal-staleness-daily') then
    perform cron.schedule(
      'goal-staleness-daily',
      '0 9 * * *',
      $job$
        select net.http_post(
          url := coalesce(current_setting('app.functions_base_url', true), 'http://kong:8000')
                 || '/functions/v1/goal-staleness-reminder',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'X-Supabase-Webhook-Secret', coalesce(
              current_setting('app.goal_staleness_secret', true),
              current_setting('app.webhook_shared_secret', true),
              ''
            )
          ),
          body := '{}'::jsonb
        );
      $job$
    );
  end if;
end
$$;

-- =============================================================================
-- Job 3: fcm-token-cleanup (03:00 UTC)
-- Sweeps revoked tokens older than 7 days and tokens not seen for 90 days.
-- =============================================================================
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'fcm-token-cleanup') then
    perform cron.schedule(
      'fcm-token-cleanup',
      '0 3 * * *',
      $job$
        delete from public.device_tokens
        where (revoked_at is not null and revoked_at < now() - interval '7 days')
           or (last_seen_at < now() - interval '90 days');
      $job$
    );
  end if;
end
$$;
