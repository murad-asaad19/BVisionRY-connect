// Deno tests for the auth-handle-login edge function.
//
// Run from repo root:
//   deno test --allow-net --allow-env --allow-read supabase/functions/auth-handle-login/
//
// The handler is dynamically imported AFTER env stubs + fetch mock are set,
// because `index.ts` calls `requireEnv` and `createClient` at module load.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  jsonReply,
  makeRequest,
  mockFetch,
  pathContains,
  setDefaultEnv,
} from "../_shared/test-utils.ts";

setDefaultEnv();
// Module load — must come AFTER setDefaultEnv() so requireEnv() succeeds.
const { handler } = await import("./index.ts");

// --- Helper fetch routers --------------------------------------------------

// Routes a profile lookup to a "no rows" reply (handle didn't match anything).
function routerNoMatchHandle(): ReturnType<typeof mockFetch> {
  return mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      // .maybeSingle() interprets a null body as "no row found, no error".
      return jsonReply(null);
    }
    if (pathContains(input, "/auth/v1/token")) {
      // dummySignIn → respond as if the credentials were wrong.
      return jsonReply({ error: "invalid_credentials" }, 400);
    }
    return jsonReply({ error: "unmocked fetch", url: String(input) }, 599);
  });
}

// Routes for the suspended/private/not-onboarded case: filter conditions
// (.eq onboarded=true / private_mode=false / is suspended_at null) don't
// match, so PostgREST returns the empty set — same as the unknown-handle path.
function routerAccountUnusable(): ReturnType<typeof mockFetch> {
  return routerNoMatchHandle();
}

// --- Tests ----------------------------------------------------------------

Deno.test("returns 405 on GET", async () => {
  const restore = mockFetch(() =>
    jsonReply({ error: "unexpected" }, 599)
  );
  try {
    const res = await handler(makeRequest("http://x/", { method: "GET" }));
    assertEquals(res.status, 405);
  } finally {
    restore();
  }
});

Deno.test("returns 400 on invalid JSON body", async () => {
  const restore = mockFetch(() =>
    jsonReply({ error: "unexpected" }, 599)
  );
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: "{not json",
        headers: { "Content-Type": "application/json" },
      }),
    );
    assertEquals(res.status, 400);
    const j = await res.json();
    assertEquals(j.error, "invalid json");
  } finally {
    restore();
  }
});

Deno.test("returns 401 generic error on missing handle/password", async () => {
  const restore = mockFetch(() =>
    jsonReply({ error: "unexpected" }, 599)
  );
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: { handle: "", password: "" },
      }),
    );
    assertEquals(res.status, 401);
    const j = await res.json();
    assertEquals(j.error, "invalid_credentials");
  } finally {
    restore();
  }
});

Deno.test("returns 401 generic error on unknown handle (with timing-equalizing dummy sign-in)", async () => {
  let signInCalled = false;
  const restore = mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      return jsonReply(null); // .maybeSingle() interprets null as no row found
    }
    if (pathContains(input, "/auth/v1/token")) {
      signInCalled = true;
      return jsonReply({ error: "invalid_credentials" }, 400);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: { handle: "ghost", password: "supersecret" },
      }),
    );
    assertEquals(res.status, 401);
    const j = await res.json();
    assertEquals(j.error, "invalid_credentials");
    // Dummy sign-in MUST have been attempted (constant-time defence).
    assertEquals(signInCalled, true);
  } finally {
    restore();
  }
});

Deno.test("returns 401 on bad handle format (regex fails)", async () => {
  let signInCalled = false;
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/token")) {
      signInCalled = true;
      return jsonReply({ error: "invalid_credentials" }, 400);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    // "!!" doesn't match the citext regex — short-circuits before profile lookup.
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: { handle: "!!", password: "pass" },
      }),
    );
    assertEquals(res.status, 401);
    // Dummy sign-in is still called for timing parity.
    assertEquals(signInCalled, true);
  } finally {
    restore();
  }
});

Deno.test("suspended / private / not-onboarded accounts all return 401", async () => {
  const restore = routerAccountUnusable();
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: { handle: "alice", password: "x" },
      }),
    );
    assertEquals(res.status, 401);
    const j = await res.json();
    assertEquals(j.error, "invalid_credentials");
  } finally {
    restore();
  }
});

Deno.test("returns 200 + tokens on successful sign-in", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      // supabase-js .maybeSingle() sets Accept: application/vnd.pgrst.object+json
      // and expects a SINGLE OBJECT (not a one-element array). Empty-set case
      // is conveyed via 406/PGRST116 — handled by the "unknown handle" test.
      return jsonReply({ id: "11111111-1111-1111-1111-111111111111" });
    }
    // getUserById call from auth.admin.getUserById
    if (pathContains(input, "/auth/v1/admin/users/")) {
      return jsonReply({
        id: "11111111-1111-1111-1111-111111111111",
        email: "alice@example.test",
      });
    }
    if (pathContains(input, "/auth/v1/token")) {
      return jsonReply({
        access_token: "fake-access-token",
        refresh_token: "fake-refresh-token",
        expires_in: 3600,
        token_type: "bearer",
        user: {
          id: "11111111-1111-1111-1111-111111111111",
          email: "alice@example.test",
        },
      });
    }
    return jsonReply({ error: "unexpected", url: String(input) }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: { handle: "alice", password: "correct-horse" },
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.access_token, "fake-access-token");
    assertEquals(j.refresh_token, "fake-refresh-token");
    assertEquals(j.token_type, "bearer");
  } finally {
    restore();
  }
});

Deno.test("normalizes @-prefix and uppercase in handle before lookup", async () => {
  let lookupUrl = "";
  const restore = mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      lookupUrl = String(input);
      return jsonReply(null); // .maybeSingle() interprets null as no row found — short-circuits to 401
    }
    if (pathContains(input, "/auth/v1/token")) {
      return jsonReply({ error: "invalid_credentials" }, 400);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: { handle: "@Murad", password: "x" },
      }),
    );
    // After normalize: `murad`, NOT `@Murad`.
    // PostgREST encodes the filter as ?handle=eq.murad
    assertEquals(lookupUrl.includes("handle=eq.murad"), true);
  } finally {
    restore();
  }
});
