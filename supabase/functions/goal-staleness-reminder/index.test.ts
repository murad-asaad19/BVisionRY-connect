// Deno tests for the goal-staleness-reminder edge function.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  jsonReply,
  makeRequest,
  mockFetch,
  pathContains,
  setDefaultEnv,
} from "../_shared/test-utils.ts";

setDefaultEnv();
// MAILER_KEY intentionally NOT set → handler runs in stub mode and reports
// would_email. This file exercises the stub branch (which is what dev/CI sees).
const { handler } = await import("./index.ts");

const WEBHOOK_SECRET = "test-webhook-secret"; // mirrors setDefaultEnv()
const AUTH_HEADERS = { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET };

// --- Tests ----------------------------------------------------------------

Deno.test("returns 401 when X-Supabase-Webhook-Secret header is missing", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(makeRequest("http://x/", { method: "POST" }));
    assertEquals(res.status, 401);
  } finally {
    restore();
  }
});

Deno.test("returns 401 when webhook secret is wrong", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        headers: { "X-Supabase-Webhook-Secret": "wrong-secret" },
      }),
    );
    assertEquals(res.status, 401);
  } finally {
    restore();
  }
});

Deno.test("returns 200 + candidates:0 when no stale profiles", async () => {
  // Response field is `candidates` (not `emailed`) — mailer integration is
  // pending; the field name reflects "count of users we WOULD email",
  // never "count of mail sent".
  let queriedProfiles = false;
  let cutoffSeenInQuery: string | null = null;
  const restore = mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      queriedProfiles = true;
      // PostgREST encodes filters as ?goal_updated_at=lt.<iso>&onboarded=eq.true
      // Capture the cutoff for the next assertion.
      const m = String(input).match(/goal_updated_at=lt\.([^&]+)/);
      if (m) cutoffSeenInQuery = decodeURIComponent(m[1]);
      return jsonReply([]); // no stale users
    }
    return jsonReply({ error: "unexpected", url: String(input) }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", { method: "POST", headers: AUTH_HEADERS }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.ok, true);
    assertEquals(j.candidates, 0);
    assertEquals(queriedProfiles, true);
  } finally {
    restore();
  }
  // The cutoff should be a valid ISO timestamp ~56 days in the past.
  if (cutoffSeenInQuery) {
    const cutoffMs = Date.parse(cutoffSeenInQuery);
    const expected = Date.now() - 56 * 24 * 60 * 60 * 1000;
    // Allow a 10-second skew between the captured cutoff and "now - STALE_DAYS".
    const diff = Math.abs(cutoffMs - expected);
    if (diff > 10_000) {
      throw new Error(`cutoff ${cutoffSeenInQuery} not within 10s of expected; diff=${diff}ms`);
    }
  }
});

Deno.test("returns stub:true + would_email count when MAILER_KEY missing and stale users found", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      return jsonReply([
        { id: "u1", handle: "alice", name: "Alice" },
        { id: "u2", handle: "bob",   name: "Bob" },
      ]);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", { method: "POST", headers: AUTH_HEADERS }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.ok, true);
    assertEquals(j.stub, true);
    assertEquals(j.would_email, 2);
  } finally {
    restore();
  }
});

Deno.test("returns 500 when the profiles query errors", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      return jsonReply({ message: "db down" }, 500);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", { method: "POST", headers: AUTH_HEADERS }),
    );
    assertEquals(res.status, 500);
  } finally {
    restore();
  }
});

Deno.test("queries with onboarded=true filter", async () => {
  let onboardedFilterSeen = false;
  const restore = mockFetch((input) => {
    if (pathContains(input, "/rest/v1/profiles")) {
      if (String(input).includes("onboarded=eq.true")) onboardedFilterSeen = true;
      return jsonReply([]);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    await handler(
      makeRequest("http://x/", { method: "POST", headers: AUTH_HEADERS }),
    );
    assertEquals(onboardedFilterSeen, true);
  } finally {
    restore();
  }
});

Deno.test("preflight OPTIONS returns 204", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(makeRequest("http://x/", { method: "OPTIONS" }));
    assertEquals(res.status, 204);
  } finally {
    restore();
  }
});
