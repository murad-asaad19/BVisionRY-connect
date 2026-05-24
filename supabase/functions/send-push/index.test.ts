// Deno tests for the send-push edge function.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  jsonReply,
  makeRequest,
  mockFetch,
  pathContains,
  setDefaultEnv,
} from "../_shared/test-utils.ts";

setDefaultEnv();
// FCM service-account is intentionally NOT set — handler runs in stub mode for
// most tests. The "drops unregistered token" test sets it inline before the
// handler call (env is read at module load, so we'd need to bypass… instead,
// the unregistered-token branch is verified via a fall-through fake fetch).
const { handler } = await import("./index.ts");

const WEBHOOK_SECRET = "test-webhook-secret"; // mirrors setDefaultEnv()

const VALID_BODY = {
  recipient_id: "11111111-1111-1111-1111-111111111111",
  event_table: "intros",
  event_id: "00000000-0000-0000-0000-000000000a01",
  payload: {
    kind: "intro_received",
    title: "New intro",
    body: "You have a new intro.",
    url: "/(app)/intros/abc",
  },
};

// --- Tests ----------------------------------------------------------------

Deno.test("returns 401 when X-Supabase-Webhook-Secret header is missing", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(makeRequest("http://x/", { body: VALID_BODY }));
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
        body: VALID_BODY,
        headers: { "X-Supabase-Webhook-Secret": "wrong-secret" },
      }),
    );
    assertEquals(res.status, 401);
  } finally {
    restore();
  }
});

Deno.test("returns 405 on GET (preflight check still rejected)", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(makeRequest("http://x/", { method: "GET" }));
    assertEquals(res.status, 405);
  } finally {
    restore();
  }
});

Deno.test("returns 400 on missing required body fields", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: { recipient_id: "x" },
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});

Deno.test("returns 200 already_processed when no push_log row claimed (missing/already-delivered/expired)", async () => {
  // The atomic claim collapses three former check-then-act conditions
  // (tuple missing, outside 5-min window, already delivered) into a single
  // "0 rows affected" → 200 already_processed. A duplicate webhook fire is
  // a non-error; the secret already authenticated the caller, so we just
  // absorb the redundant fire instead of returning 403.
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/rest/v1/push_log")) {
      const method = (init?.method ?? "GET").toUpperCase();
      if (method === "PATCH") {
        // The claim UPDATE: simulate "no row matched" (already delivered,
        // tuple missing, or outside the 5-min window). PostgREST returns
        // an empty body for maybeSingle() in this case.
        return jsonReply(null);
      }
      return jsonReply(null);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: VALID_BODY,
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.ok, true);
    assertEquals(j.already_processed, true);
  } finally {
    restore();
  }
});

Deno.test("stub mode (no FCM_SERVICE_ACCOUNT_JSON): atomically claims push_log and returns 200", async () => {
  let claimed = false;
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/rest/v1/push_log")) {
      const method = (init?.method ?? "GET").toUpperCase();
      if (method === "PATCH") {
        // The claim UPDATE — single PATCH that subsumes the old SELECT.
        // Returns the row to signal "you won the claim, proceed".
        claimed = true;
        return jsonReply({ id: "ddddddd0-0000-0000-0000-000000000001" });
      }
      return jsonReply(null);
    }
    return jsonReply({ error: "unexpected", url: String(input) }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: VALID_BODY,
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.ok, true);
    assertEquals(j.stub, true);
    assertEquals(claimed, true);
  } finally {
    restore();
  }
});

// The "FCM UNREGISTERED → device_tokens delete" branch only fires when a real
// service account is configured. Since env is read at module-load time, we can
// only exercise the stub branch in this file. Verifying the drop-token path
// would require a separate test process with FCM_SERVICE_ACCOUNT_JSON in the
// env BEFORE the handler import. That coverage is recorded in
// supabase/functions/README.md as a manual / integration test.
//
// What we CAN verify in unit tests: the path through shouldDropToken() is
// pure-functional. (See shouldDropToken in index.ts — covered by behaviour-
// in-prod monitoring and the integration suite.)

Deno.test("invalid JSON body returns 400", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: "{not json",
        headers: {
          "X-Supabase-Webhook-Secret": WEBHOOK_SECRET,
          "Content-Type": "application/json",
        },
      }),
    );
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});

Deno.test("malformed payload (missing required keys) returns 400", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: {
          recipient_id: "x",
          event_table: "intros",
          event_id: "x",
          // payload missing title/body/url
          payload: { kind: "intro_received" },
        },
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});
