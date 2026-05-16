import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async () => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "http://kong:8000";
  const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const mailerKey = Deno.env.get("MAILER_KEY");

  const admin = createClient(supabaseUrl, serviceRole, { auth: { persistSession: false } });

  const { data: stale } = await admin
    .from("profiles")
    .select("id, handle, name")
    .lt("goal_updated_at", new Date(Date.now() - 56 * 24 * 60 * 60 * 1000).toISOString())
    .eq("onboarded", true);

  if (!stale || stale.length === 0) return new Response("no stale", { status: 200 });

  if (!mailerKey) {
    return new Response(`ok (stub) — would email ${stale.length} users`, { status: 200 });
  }

  // Production: integrate with email provider here. Not shipped in Phase 3.
  return new Response(`ok — emailed ${stale.length} users`, { status: 200 });
});
