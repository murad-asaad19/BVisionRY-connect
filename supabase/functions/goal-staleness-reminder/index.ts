import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import {
  optionalEnv,
  requireEnv,
  verifyWebhookSecret,
} from "../_shared/env.ts";

const SUPABASE_URL = requireEnv("SUPABASE_URL");
const SERVICE_ROLE = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
const WEBHOOK_SECRET = requireEnv("WEBHOOK_SHARED_SECRET");
const MAILER_KEY = optionalEnv("MAILER_KEY");

// Profiles whose goal_updated_at is older than this many days are "stale".
const STALE_DAYS = 56;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { persistSession: false },
});

// Exported for unit tests (see index.test.ts).
export async function handler(req: Request): Promise<Response> {
  const pre = handlePreflight(req);
  if (pre) return pre;

  // Cron sends X-Supabase-Webhook-Secret (see 20260606140000_scheduled_jobs.sql).
  // Reject anything else — this endpoint is not for end-user clients.
  if (!verifyWebhookSecret(req, WEBHOOK_SECRET)) {
    console.error({
      fn: "goal-staleness-reminder",
      stage: "auth",
      err: "bad secret",
    });
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  try {
    const cutoff = new Date(
      Date.now() - STALE_DAYS * 24 * 60 * 60 * 1000,
    ).toISOString();

    const { data: stale, error } = await admin
      .from("profiles")
      .select("id, handle, name")
      .lt("goal_updated_at", cutoff)
      .eq("onboarded", true);

    if (error) {
      console.error({
        fn: "goal-staleness-reminder",
        stage: "query",
        err: String(error.message ?? error),
      });
      return jsonResponse({ error: "query failed" }, 500);
    }

    const count = stale?.length ?? 0;
    if (count === 0) return jsonResponse({ ok: true, candidates: 0 }, 200);

    if (!MAILER_KEY) {
      return jsonResponse({ ok: true, stub: true, would_email: count }, 200);
    }

    // TODO: integrate with email provider here. Mailer integration is
    // pending — for now we only report the count of stale-goal candidates
    // (NOT a count of sent mail). Field name reflects that: `candidates`,
    // never `emailed`, until the dispatch path is actually implemented.
    return jsonResponse({ ok: true, candidates: count }, 200);
  } catch (err) {
    console.error({
      fn: "goal-staleness-reminder",
      stage: "fatal",
      err: String(err),
    });
    return jsonResponse({ error: "internal" }, 500);
  }
}

serve(handler);
