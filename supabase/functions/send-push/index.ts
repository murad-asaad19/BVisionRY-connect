import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.1/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import { optionalEnv, requireEnv, verifyWebhookSecret } from "../_shared/env.ts";

// Legacy localized payload composed by the SQL `dispatch_push` function. Kept
// for backwards compat — the dev stub and any FCM clients that haven't
// migrated to client-side localization still rely on `title/body/url`.
//
// Warm-forward intros also carry `via_user_id` and `via_user_name` inside the
// payload (see notify_intro_inserted in 20260608060000_warm_intros_fixes.sql).
// We surface them in FCM `data` so the mobile client can render a prominent
// "Forwarded by {name}" caption above the note when it opens the intro from
// a push.
type LegacyPayload = {
  kind: string;
  title: string;
  body: string;
  url: string;
  via_user_id?: string;
  via_user_name?: string;
};

// Structured data forwarded into FCM `message.data` so clients can route and
// localize deterministically. All fields optional; SQL omits the whole `data`
// object when none were supplied (legacy callers).
type StructuredData = {
  kind?: string;
  entity_id?: string;
  conversation_id?: string;
};

type RequestBody = {
  recipient_id: string;
  event_table: string;
  event_id: string;
  payload: LegacyPayload;
  data?: StructuredData | null;
};

// RFC 4122 UUID (any version). Anchored — must match the whole string.
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Validates the request body shape. Returns null on success or an error string.
function validateBody(b: unknown): { ok: true; body: RequestBody } | { ok: false; err: string } {
  if (!b || typeof b !== "object") return { ok: false, err: "body must be an object" };
  const r = b as Record<string, unknown>;
  if (typeof r.recipient_id !== "string" || r.recipient_id.length === 0) {
    return { ok: false, err: "recipient_id required" };
  }
  if (!UUID_RE.test(r.recipient_id)) {
    return { ok: false, err: "recipient_id must be a uuid" };
  }
  if (typeof r.event_table !== "string" || r.event_table.length === 0) {
    return { ok: false, err: "event_table required" };
  }
  if (typeof r.event_id !== "string" || r.event_id.length === 0) {
    return { ok: false, err: "event_id required" };
  }
  if (!UUID_RE.test(r.event_id)) {
    return { ok: false, err: "event_id must be a uuid" };
  }
  const p = r.payload as Record<string, unknown> | undefined;
  if (!p || typeof p !== "object") return { ok: false, err: "payload required" };
  if (typeof p.kind !== "string" || typeof p.title !== "string" ||
      typeof p.body !== "string" || typeof p.url !== "string") {
    return { ok: false, err: "payload must have kind/title/body/url strings" };
  }
  // Optional warm-forward fields. Validate type when present — null and
  // undefined are both fine (jsonb_strip_nulls drops them at the SQL layer for
  // non-warm_forward intros).
  if (p.via_user_id !== undefined && p.via_user_id !== null && typeof p.via_user_id !== "string") {
    return { ok: false, err: "payload.via_user_id must be a string" };
  }
  if (
    p.via_user_name !== undefined && p.via_user_name !== null &&
    typeof p.via_user_name !== "string"
  ) {
    return { ok: false, err: "payload.via_user_name must be a string" };
  }
  // data is optional — when present, every field must be a string.
  let data: StructuredData | null = null;
  if (r.data !== undefined && r.data !== null) {
    if (typeof r.data !== "object") return { ok: false, err: "data must be an object" };
    const d = r.data as Record<string, unknown>;
    for (const k of Object.keys(d)) {
      if (typeof d[k] !== "string") return { ok: false, err: `data.${k} must be a string` };
    }
    data = d as StructuredData;
  }
  return {
    ok: true,
    body: {
      recipient_id: r.recipient_id,
      event_table: r.event_table,
      event_id: r.event_id,
      payload: p as unknown as LegacyPayload,
      data,
    },
  };
}

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const PUSH_LOG_WINDOW_MS = 5 * 60 * 1000; // 5 minutes

// Required envs — assert at module load.
const SUPABASE_URL = requireEnv("SUPABASE_URL");
const SERVICE_ROLE = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
const WEBHOOK_SECRET = requireEnv("WEBHOOK_SHARED_SECRET");

// FCM_SERVICE_ACCOUNT_JSON is optional — when missing OR malformed the
// function runs in stub mode and only flips push_log.delivered (used in dev).
// Parse failures must NOT brick the cold-start; we log and fall through.
const RAW_SA = optionalEnv("FCM_SERVICE_ACCOUNT_JSON");
const SERVICE_ACCOUNT: ServiceAccount | null = (() => {
  if (!RAW_SA) return null;
  try {
    return JSON.parse(RAW_SA) as ServiceAccount;
  } catch (err) {
    console.error({
      fn: "send-push",
      stage: "service-account-parse",
      err: `FCM_SERVICE_ACCOUNT_JSON failed to parse: ${String(err)}`,
    });
    return null;
  }
})();

const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { persistSession: false },
});

// Module-scope OAuth access-token cache.
let tokenCache: { token: string; expiresAt: number } | null = null;

// Module-scope cached private key import (avoid re-importing on every call).
let signingKeyPromise: Promise<CryptoKey> | null = null;

function pemToBytes(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

function getSigningKey(sa: ServiceAccount): Promise<CryptoKey> {
  if (!signingKeyPromise) {
    signingKeyPromise = crypto.subtle.importKey(
      "pkcs8",
      pemToBytes(sa.private_key),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
  }
  return signingKeyPromise;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Date.now();
  if (tokenCache && tokenCache.expiresAt - now > 60_000) {
    return tokenCache.token;
  }

  const iat = getNumericDate(0);
  const key = await getSigningKey(sa);
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: sa.client_email,
      scope: FCM_SCOPE,
      aud: "https://oauth2.googleapis.com/token",
      iat,
      exp: getNumericDate(60 * 60),
    },
    key,
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    tokenCache = null;
    throw new Error(`oauth token fetch failed: ${res.status}`);
  }
  const json = await res.json();
  const accessToken: string | undefined = json.access_token;
  const expiresIn: number = typeof json.expires_in === "number"
    ? json.expires_in
    : 3600;
  if (!accessToken) {
    tokenCache = null;
    throw new Error("oauth token response missing access_token");
  }
  tokenCache = { token: accessToken, expiresAt: Date.now() + expiresIn * 1000 };
  return accessToken;
}

type FcmResult = { ok: true } | {
  ok: false;
  status: number;
  errorCode: string | null;
  message: string;
};

// FCM v1 errors look like:
//   { "error": { "code": 404, "status": "NOT_FOUND",
//                "message": "...",
//                "details": [{ "@type": "...", "errorCode": "UNREGISTERED" }] } }
// We treat UNREGISTERED / INVALID_REGISTRATION / SENDER_ID_MISMATCH /
// THIRD_PARTY_AUTH_ERROR / HTTP 404 / legacy "registration-token-not-registered"
// as an instruction to drop the token row. All five mean the token will never
// successfully receive a push from this project again:
//   - UNREGISTERED / INVALID_REGISTRATION: the app instance is gone.
//   - SENDER_ID_MISMATCH: the token was issued to a different FCM sender.
//   - THIRD_PARTY_AUTH_ERROR: the APNs cert/key is invalid or revoked, so
//     iOS pushes can never reach the device.
//
// IMPORTANT: do NOT drop on generic INVALID_ARGUMENT. FCM v1 returns
// INVALID_ARGUMENT for many reasons that are NOT token-fatal — malformed
// notification payload, oversized data field, missing required field, etc.
// Dropping the device row in those cases silently removes healthy tokens.
// We log INVALID_ARGUMENT at the call site instead and leave the row in place.
function shouldDropToken(r: FcmResult & { ok: false }): boolean {
  if (r.status === 404) return true;
  if (r.errorCode === "UNREGISTERED") return true;
  if (r.errorCode === "INVALID_REGISTRATION") return true;
  if (r.errorCode === "SENDER_ID_MISMATCH") return true;
  if (r.errorCode === "THIRD_PARTY_AUTH_ERROR") return true;
  if (r.message.includes("registration-token-not-registered")) return true;
  return false;
}

async function sendToToken(
  accessToken: string,
  projectId: string,
  token: string,
  body: RequestBody,
): Promise<FcmResult> {
  // Merge the legacy `payload` (url + kind) with any structured `data` from
  // the SQL caller. Structured fields win on key collision so the SQL-supplied
  // kind/entity_id/conversation_id are authoritative when both are present.
  // FCM v1 requires every value in `data` to be a string.
  const fcmData: Record<string, string> = {
    url:  body.payload.url,
    kind: body.payload.kind,
  };
  // Warm-forward intros carry forwarder identity in the legacy payload — copy
  // them into FCM data so the mobile client can render "Forwarded by {name}"
  // without a separate fetch on push tap.
  if (body.payload.via_user_id) fcmData.via_user_id = body.payload.via_user_id;
  if (body.payload.via_user_name) fcmData.via_user_name = body.payload.via_user_name;
  if (body.data) {
    if (body.data.kind) fcmData.kind = body.data.kind;
    if (body.data.entity_id) fcmData.entity_id = body.data.entity_id;
    if (body.data.conversation_id) fcmData.conversation_id = body.data.conversation_id;
  }

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: body.payload.title, body: body.payload.body },
          data: fcmData,
          android: { priority: "HIGH" },
        },
      }),
    },
  );
  if (res.ok) return { ok: true };
  let errorCode: string | null = null;
  let message = "";
  try {
    const j = await res.json();
    message = j?.error?.message ?? "";
    const details: Array<Record<string, unknown>> = j?.error?.details ?? [];
    for (const d of details) {
      if (typeof d.errorCode === "string") {
        errorCode = d.errorCode;
        break;
      }
    }
  } catch {
    // body wasn't JSON — keep defaults
  }
  return { ok: false, status: res.status, errorCode, message };
}

async function dropToken(token: string): Promise<void> {
  const { error } = await admin
    .from("device_tokens")
    .delete()
    .eq("token", token);
  if (error) {
    console.error({
      fn: "send-push",
      stage: "drop-token",
      err: String(error.message ?? error),
    });
  }
}

// Exported for unit tests (see index.test.ts).
export async function handler(req: Request): Promise<Response> {
  const pre = handlePreflight(req);
  if (pre) return pre;

  if (req.method !== "POST") {
    return jsonResponse({ error: "only POST" }, 405);
  }

  if (!verifyWebhookSecret(req, WEBHOOK_SECRET)) {
    console.error({ fn: "send-push", stage: "auth", err: "bad secret" });
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return jsonResponse({ error: "invalid json" }, 400);
  }

  const parsed = validateBody(raw);
  if (!parsed.ok) {
    return jsonResponse({ error: parsed.err }, 400);
  }
  const body = parsed.body;

  // Atomically claim the (event_table, event_id, recipient_id) tuple in
  // push_log. The single UPDATE subsumes three checks that used to be
  // separate SELECT-then-act conditions, all of which had check-then-act
  // races between duplicate webhook fires:
  //
  //   - tuple exists in push_log (binds endpoint to a real dispatch_push call)
  //   - created within the last 5 minutes (replay/spam protection)
  //   - delivered is still false (in-flight dedup against retry storms)
  //
  // Whichever fire wins the row sets delivered=true and proceeds with the
  // FCM fanout. The losers (or a tuple that never existed, or one outside
  // the window) all collapse into "0 rows affected" → return 200. We
  // revert delivered=false in any failure path below so a subsequent
  // sequential retry can re-claim the same row.
  const cutoffIso = new Date(Date.now() - PUSH_LOG_WINDOW_MS).toISOString();
  const { data: claimed, error: claimErr } = await admin
    .from("push_log")
    .update({ delivered: true, error: null })
    .eq("event_table", body.event_table)
    .eq("event_id", body.event_id)
    .eq("recipient_id", body.recipient_id)
    .eq("delivered", false)
    .gt("created_at", cutoffIso)
    .select("id")
    .maybeSingle();

  if (claimErr) {
    console.error({
      fn: "send-push",
      stage: "push_log-claim",
      err: String(claimErr.message ?? claimErr),
    });
    return jsonResponse({ error: "claim failed" }, 500);
  }
  if (!claimed) {
    // Tuple missing, outside window, or already claimed by a sibling fire.
    // All three are non-errors at this layer: the SQL trigger guarantees
    // the row exists when the dispatch is legitimate, and a duplicate
    // webhook should be silently absorbed.
    return jsonResponse({ ok: true, already_processed: true }, 200);
  }

  // Helper: revert the claim so a later retry can pick the row up again.
  // Used on every failure path between here and the final fanout result.
  async function revertClaim(reason: string): Promise<void> {
    const { error: revErr } = await admin
      .from("push_log")
      .update({ delivered: false, error: reason })
      .eq("event_table", body.event_table)
      .eq("event_id", body.event_id)
      .eq("recipient_id", body.recipient_id);
    if (revErr) {
      console.error({
        fn: "send-push",
        stage: "push_log-revert",
        err: String(revErr.message ?? revErr),
      });
    }
  }

  // Stub mode: no service-account configured. The claim already flipped
  // delivered=true; nothing else to do.
  if (!SERVICE_ACCOUNT) {
    return jsonResponse({ ok: true, stub: true }, 200);
  }

  // Look up device tokens for the recipient. Skip any that have been revoked
  // (sign-out, manual revocation, or token rotation) — the row is kept around
  // for the FCM-token-cleanup sweep but must NOT receive new pushes.
  const { data: tokens, error: tokensError } = await admin
    .from("device_tokens")
    .select("token, platform")
    .eq("user_id", body.recipient_id)
    .is("revoked_at", null);

  if (tokensError) {
    console.error({
      fn: "send-push",
      stage: "tokens",
      err: String(tokensError.message),
    });
    await revertClaim(tokensError.message);
    return jsonResponse({ error: "token lookup failed" }, 500);
  }

  // Only iOS/Android tokens go through FCM. (Web is out of scope here.)
  const mobileTokens = (tokens ?? []).filter((t) => t.platform !== "web");
  if (mobileTokens.length === 0) {
    // No tokens is a terminal non-error — there's nothing to retry. Keep
    // delivered=true (already set by the claim) and just stamp the reason.
    await admin
      .from("push_log")
      .update({ error: "no tokens" })
      .eq("event_table", body.event_table)
      .eq("event_id", body.event_id)
      .eq("recipient_id", body.recipient_id);
    return jsonResponse({ ok: true, tokens: 0 }, 200);
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(SERVICE_ACCOUNT);
  } catch (err) {
    console.error({
      fn: "send-push",
      stage: "oauth",
      err: String(err),
    });
    await revertClaim("oauth failed");
    return jsonResponse({ error: "oauth failed" }, 502);
  }

  // Parallel fanout — each token result is isolated; one failure doesn't
  // sink the whole batch.
  const projectId = SERVICE_ACCOUNT.project_id;
  const results = await Promise.all(
    mobileTokens.map(async (t) => {
      try {
        const r = await sendToToken(
          accessToken,
          projectId,
          t.token,
          body,
        );
        if (!r.ok) {
          // Surface INVALID_ARGUMENT distinctly — likely a malformed payload
          // bug on OUR side, not a stale token. Do not drop the row.
          if (r.errorCode === "INVALID_ARGUMENT") {
            console.warn({
              fn: "send-push",
              stage: "fanout",
              err: `FCM INVALID_ARGUMENT for token (token kept): ${r.message}`,
            });
          }
          if (shouldDropToken(r)) {
            await dropToken(t.token);
          }
        }
        return r;
      } catch (err) {
        console.error({
          fn: "send-push",
          stage: "fanout",
          err: String(err),
        });
        return {
          ok: false as const,
          status: 0,
          errorCode: null,
          message: String(err),
        };
      }
    }),
  );

  const failures = results.filter((r): r is FcmResult & { ok: false } =>
    !r.ok
  );
  const allOk = failures.length === 0;
  const errSummary = failures.length
    ? failures
      .map((f) => `${f.status}/${f.errorCode ?? "?"}/${f.message}`)
      .join("; ")
    : null;

  if (allOk) {
    // delivered=true was already set by the claim; just clear the error
    // column in case a prior attempt left a stale string behind.
    await admin
      .from("push_log")
      .update({ error: null })
      .eq("event_table", body.event_table)
      .eq("event_id", body.event_id)
      .eq("recipient_id", body.recipient_id);
  } else {
    // Total or partial fanout failure — revert the claim so the next retry
    // can re-fire. We preserve the prior semantic of `delivered = allOk`
    // (any failure marks the whole dispatch as not delivered).
    await revertClaim(errSummary ?? "fanout failed");
  }

  return jsonResponse(
    {
      ok: allOk,
      sent: results.length - failures.length,
      failed: failures.length,
    },
    200,
  );
}

serve(handler);
