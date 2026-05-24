// Pre-login endpoint that resolves a public @handle to the associated
// auth.users email server-side, then calls signInWithPassword. This exists
// so the handle → email mapping is no longer exposed to anon clients via
// an RPC (see 20260606060000_revoke_handle_lookup.sql).
//
// verify_jwt = false in supabase/config.toml — the caller is unauthenticated
// at sign-in time. The function validates its own credentials.
//
// All failure modes return a generic 401 with `{error: 'invalid_credentials'}`.
// We never distinguish "unknown handle", "wrong password", "suspended",
// "private", or "not onboarded" — that would let anon clients enumerate
// account state. A dummy signInWithPassword call on the unknown-handle path
// roughly equalizes wall-clock timing (defense-in-depth, not a guarantee).

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handlePreflight, jsonResponse } from "../_shared/cors.ts";
import { requireEnv } from "../_shared/env.ts";

const SUPABASE_URL = requireEnv("SUPABASE_URL");
const SERVICE_ROLE = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
const ANON_KEY = requireEnv("SUPABASE_ANON_KEY");

// Mirror of the DB CHECK constraint on profiles.handle (slice2 migration,
// extensions.~ against an extensions.citext value): the canonical form is
// lowercase ASCII letters/digits/hyphens, must start and end with
// alphanumeric, length 1 or 3..30 chars. Citext means we lowercase before
// matching so user input like "@Murad" or "MURAD" still validates.
const HANDLE_REGEX = /^[a-z0-9](?:[a-z0-9-]{1,28}[a-z0-9])?$/;

// Reserved RFC-2606 TLD — guaranteed never to collide with a real account.
const DUMMY_EMAIL = "nobody@example.invalid";

type LoginBody = {
  handle?: unknown;
  password?: unknown;
};

const INVALID_CREDENTIALS = { error: "invalid_credentials" } as const;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { persistSession: false },
});

function normalizeHandle(raw: string): string {
  return raw.trim().replace(/^@+/, "").toLowerCase();
}

async function dummySignIn(password: string): Promise<void> {
  // Defense-in-depth: even on unknown-handle, do a real signInWithPassword
  // against a sentinel email so the response time of an unknown-handle
  // attempt roughly matches a known-handle-wrong-password attempt. Failure
  // is expected and discarded.
  try {
    const anon = createClient(SUPABASE_URL, ANON_KEY, {
      auth: { persistSession: false },
    });
    await anon.auth.signInWithPassword({
      email: DUMMY_EMAIL,
      password,
    });
  } catch {
    // Swallow — this call is purely timing-equalization.
  }
}

// Exported for unit tests (see index.test.ts). The default `serve(handler)`
// boot path below is the only thing that runs in production.
export async function handler(req: Request): Promise<Response> {
  const pre = handlePreflight(req);
  if (pre) return pre;

  if (req.method !== "POST") {
    return jsonResponse({ error: "only POST" }, 405);
  }

  let body: LoginBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid json" }, 400);
  }

  const rawHandle = typeof body.handle === "string" ? body.handle : "";
  const password = typeof body.password === "string" ? body.password : "";

  if (!rawHandle || !password) {
    return jsonResponse(INVALID_CREDENTIALS, 401);
  }

  const handle = normalizeHandle(rawHandle);
  if (!handle || !HANDLE_REGEX.test(handle)) {
    // Bad handle format never matches a real account — short-circuit but
    // still burn time on a dummy sign-in for timing parity.
    await dummySignIn(password);
    return jsonResponse(INVALID_CREDENTIALS, 401);
  }

  // One service-role query that bundles every "account is usable" filter:
  //  - handle matches (citext equality, case-insensitive by column type)
  //  - onboarded (defence-in-depth; handles are set during onboarding)
  //  - not private_mode
  //  - not suspended
  // We can't reuse public.lookup_email_by_handle here — its RPC contract
  // doesn't carry these filters, and we can't widen it without breaking
  // callers (it's now deprecated and revoked from anon anyway).
  const { data: row, error: lookupErr } = await admin
    .from("profiles")
    .select("id")
    .eq("handle", handle)
    .eq("onboarded", true)
    .eq("private_mode", false)
    .is("suspended_at", null)
    .maybeSingle();

  if (lookupErr) {
    console.error({
      fn: "auth-handle-login",
      stage: "profile-lookup",
      err: String(lookupErr.message ?? lookupErr),
    });
    // Don't leak DB failures as 500 to anon — fall through as 401.
    await dummySignIn(password);
    return jsonResponse(INVALID_CREDENTIALS, 401);
  }

  let email: string | null = null;
  if (row?.id) {
    // Read the email via the admin auth API — safer than relying on
    // PostgREST exposing the `auth` schema.
    const { data: userData, error: userErr } = await admin.auth.admin
      .getUserById(row.id);
    if (userErr) {
      console.error({
        fn: "auth-handle-login",
        stage: "auth-user-lookup",
        err: String(userErr.message ?? userErr),
      });
      await dummySignIn(password);
      return jsonResponse(INVALID_CREDENTIALS, 401);
    }
    email = userData?.user?.email ?? null;
  }

  if (!email) {
    // Unknown handle, unusable account, or no email on auth row. Burn time
    // on a dummy sign-in before responding so wall-clock timing doesn't
    // distinguish the case from "known handle, wrong password".
    await dummySignIn(password);
    return jsonResponse(INVALID_CREDENTIALS, 401);
  }

  // Real sign-in via anon-key client. We use the anon key so the resulting
  // session is shaped exactly like a normal signInWithPassword response;
  // RLS/permission contracts on the returned access_token are unchanged.
  const anon = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { persistSession: false },
  });

  const { data: signInData, error: signInErr } = await anon.auth
    .signInWithPassword({ email, password });

  if (signInErr || !signInData?.session) {
    if (signInErr) {
      // Stage label only — never log handle, email, or session fields.
      console.error({
        fn: "auth-handle-login",
        stage: "sign-in",
        err: String(signInErr.message ?? signInErr),
      });
    }
    return jsonResponse(INVALID_CREDENTIALS, 401);
  }

  // Only return the two tokens. The user object is recoverable by the
  // mobile client from the access_token (supabase.auth.setSession populates
  // currentUser from the JWT), so there's no need to ship the full profile
  // back to an anon caller.
  const s = signInData.session;
  return jsonResponse(
    {
      access_token: s.access_token,
      refresh_token: s.refresh_token,
      expires_in: s.expires_in,
      token_type: s.token_type,
    },
    200,
  );
}

serve(handler);
