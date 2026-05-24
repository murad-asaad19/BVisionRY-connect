import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  handlePreflightRestricted,
  jsonResponseRestricted,
} from "../_shared/cors.ts";
import { optionalEnv, requireEnv } from "../_shared/env.ts";

const SUPABASE_URL = requireEnv("SUPABASE_URL");
const SERVICE_ROLE = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
const ANON_KEY = requireEnv("SUPABASE_ANON_KEY");

// Default allow-list — webapp domain + the mobile Expo custom scheme.
// Override per-deployment via DELETE_ACCOUNT_ALLOWED_ORIGINS as a comma-separated list.
const DEFAULT_ALLOWED_ORIGINS = [
  "https://app.bvisionry.com",
  "connect-mobile://",
];
const ALLOWED_ORIGINS: readonly string[] = (() => {
  const raw = optionalEnv("DELETE_ACCOUNT_ALLOWED_ORIGINS");
  if (!raw) return DEFAULT_ALLOWED_ORIGINS;
  return raw.split(",").map((s) => s.trim()).filter((s) => s.length > 0);
})();

// Exported for unit tests (see index.test.ts).
export async function handler(req: Request): Promise<Response> {
  const pre = handlePreflightRestricted(req, ALLOWED_ORIGINS);
  if (pre) return pre;

  if (req.method !== "POST") {
    return jsonResponseRestricted(req, ALLOWED_ORIGINS, { error: "only POST" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponseRestricted(req, ALLOWED_ORIGINS, { error: "unauthorized" }, 401);
  }
  const jwt = authHeader.replace(/^Bearer\s+/i, "");

  // Per-request client bound to the user's JWT — for getUser + RPC under RLS.
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser(jwt);
  if (userErr || !userData?.user?.id) {
    return jsonResponseRestricted(req, ALLOWED_ORIGINS, { error: "unauthorized" }, 401);
  }
  const userId = userData.user.id;

  // Step 1: wipe app-level rows via SECURITY DEFINER RPC, as the user.
  // The RPC is idempotent — re-running on an already-deleted user is a no-op.
  const { error: rpcErr } = await userClient.rpc("delete_my_account");
  if (rpcErr) {
    console.error({
      fn: "delete-account",
      stage: "rpc",
      err: String(rpcErr.message ?? rpcErr),
    });
    return jsonResponseRestricted(req, ALLOWED_ORIGINS, { error: "wipe failed" }, 500);
  }

  // Step 2: admin-delete auth.users. Treat "user not found" as success (idempotent).
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });
  const { error: delErr } = await admin.auth.admin.deleteUser(userId);
  if (delErr) {
    const msg = String(delErr.message ?? "").toLowerCase();
    const notFound =
      msg.includes("not found") || msg.includes("user_not_found");
    if (!notFound) {
      console.error({
        fn: "delete-account",
        stage: "auth-delete",
        err: String(delErr.message ?? delErr),
      });
      return jsonResponseRestricted(
        req,
        ALLOWED_ORIGINS,
        { error: "auth delete failed" },
        500,
      );
    }
  }

  return jsonResponseRestricted(req, ALLOWED_ORIGINS, { ok: true }, 200);
}

serve(handler);
