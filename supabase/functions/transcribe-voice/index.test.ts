// Deno tests for the transcribe-voice edge function.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  jsonReply,
  makeRequest,
  mockFetch,
  pathContains,
  setDefaultEnv,
} from "../_shared/test-utils.ts";

setDefaultEnv();
// WHISPER/OPENAI keys NOT set → stub mode for the "stub" test. Tests that
// exercise the real Whisper branch set WHISPER_API_KEY before module load via
// the local override below.
Deno.env.set("WHISPER_API_KEY", "test-whisper-key");
const { handler } = await import("./index.ts");

const WEBHOOK_SECRET = "test-webhook-secret";
const MSG_ID = "ccccccc1-0000-0000-0000-000000000001";

// --- Tests ----------------------------------------------------------------

Deno.test("returns 401 without webhook secret", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", { body: { message_id: MSG_ID } }),
    );
    assertEquals(res.status, 401);
  } finally {
    restore();
  }
});

Deno.test("returns 405 on GET", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(makeRequest("http://x/", { method: "GET" }));
    assertEquals(res.status, 405);
  } finally {
    restore();
  }
});

Deno.test("returns 400 on missing message_id", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: {},
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});

Deno.test("returns 400 on malformed JSON body", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: "{junk",
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

// Helper: build a messages-table mock where the FIRST PATCH (the atomic
// claim flipping 'pending' → 'processing') returns `claimRow`, and every
// subsequent PATCH is captured into `onLaterPatch` so individual tests
// can assert against the body. Returns null from the claim to simulate
// "row not claimable" (already processed, wrong kind, or missing).
function makeMessagesMock(
  claimRow: { media_path: string } | null,
  onLaterPatch?: (body: Record<string, unknown>) => void,
): (input: string | URL | Request, init?: RequestInit) => Response {
  let claimSeen = false;
  return (_input, init) => {
    const method = (init?.method ?? "GET").toUpperCase();
    if (method !== "PATCH") {
      // The new flow does no GETs against messages — every state read is
      // subsumed into the claim PATCH. Anything else is a regression.
      return jsonReply({ error: "unexpected GET on messages" }, 599);
    }
    if (!claimSeen) {
      claimSeen = true;
      return jsonReply(claimRow);
    }
    if (onLaterPatch && init?.body) {
      try {
        onLaterPatch(JSON.parse(init.body as string));
      } catch {
        /* ignore parse errors */
      }
    }
    return jsonReply([]);
  };
}

Deno.test("returns 200 skipped when message_id doesn't claim (missing, wrong kind, or already-processed)", async () => {
  // The atomic claim's filter (id=? AND kind='voice' AND transcript_status='pending')
  // collapses every non-actionable case into a single "0 rows affected" →
  // 200 skipped. Previously this branched into 404 / skipped per the
  // historical SELECT-then-act flow.
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/rest/v1/messages")) {
      return makeMessagesMock(null)(input, init);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: { message_id: MSG_ID },
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.ok, true);
    assertEquals(j.skipped, true);
  } finally {
    restore();
  }
});

Deno.test("rejects audio > 25 MiB with 413 and sets transcript_status='failed' (terminal)", async () => {
  // Oversized audio is permanent — the same row will never fit Whisper's
  // 25 MiB ceiling on a retry. We mark 'failed' to break the retry loop
  // rather than reverting to 'pending'.
  let setFailed = false;
  const big = new Uint8Array(26 * 1024 * 1024);
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/rest/v1/messages")) {
      return makeMessagesMock(
        { media_path: "convo/msg/voice.m4a" },
        (body) => {
          if (body.transcript_status === "failed" && body.transcript === null) {
            setFailed = true;
          }
        },
      )(input, init);
    }
    if (pathContains(input, "/storage/v1/object/sign/")) {
      return jsonReply({
        signedURL: "/signed-audio",
        signedUrl: "http://media.test/signed-audio",
      });
    }
    if (pathContains(input, "/signed-audio")) {
      return new Response(big, { status: 200 });
    }
    return jsonReply({ error: "unexpected", url: String(input) }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: { message_id: MSG_ID },
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 413);
    assertEquals(setFailed, true);
  } finally {
    restore();
  }
});

Deno.test("failure from Whisper reverts transcript_status to 'pending' (transient — allow retry)", async () => {
  // Whisper rate-limits, 5xx, and timeouts are transient. The next
  // dispatch should be able to re-claim and try again, so we revert to
  // 'pending' instead of marking 'failed' (which would break the retry).
  let revertedToPending = false;
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/rest/v1/messages")) {
      return makeMessagesMock(
        { media_path: "convo/msg/voice.m4a" },
        (body) => {
          if (body.transcript_status === "pending" && body.transcript === null) {
            revertedToPending = true;
          }
        },
      )(input, init);
    }
    if (pathContains(input, "/storage/v1/object/sign/")) {
      return jsonReply({
        signedURL: "/signed-audio",
        signedUrl: "http://media.test/signed-audio",
      });
    }
    if (pathContains(input, "/signed-audio")) {
      return new Response(new Uint8Array(1024), { status: 200 });
    }
    if (pathContains(input, "api.openai.com")) {
      return jsonReply({ error: { message: "boom" } }, 500);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: { message_id: MSG_ID },
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 502);
    assertEquals(revertedToPending, true);
  } finally {
    restore();
  }
});

Deno.test("download abort/timeout reverts transcript_status to 'pending' and returns 504", async () => {
  let revertedToPending = false;
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/rest/v1/messages")) {
      return makeMessagesMock(
        { media_path: "convo/msg/voice.m4a" },
        (body) => {
          if (body.transcript_status === "pending" && body.transcript === null) {
            revertedToPending = true;
          }
        },
      )(input, init);
    }
    if (pathContains(input, "/storage/v1/object/sign/")) {
      return jsonReply({
        signedURL: "/signed-audio",
        signedUrl: "http://media.test/signed-audio",
      });
    }
    if (pathContains(input, "/signed-audio")) {
      // Reject as if the AbortController had fired (we can't actually wait
      // 30s in a unit test, but throwing here exercises the same catch
      // branch as a timeout/abort would).
      return Promise.reject(new Error("aborted")) as unknown as Response;
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: { message_id: MSG_ID },
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 504);
    assertEquals(revertedToPending, true);
  } finally {
    restore();
  }
});

Deno.test("success path: returns 200 + writes transcript", async () => {
  let lastPatch: Record<string, unknown> | null = null;
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/rest/v1/messages")) {
      return makeMessagesMock(
        { media_path: "convo/msg/voice.m4a" },
        (body) => {
          lastPatch = body;
        },
      )(input, init);
    }
    if (pathContains(input, "/storage/v1/object/sign/")) {
      return jsonReply({
        signedURL: "/signed-audio",
        signedUrl: "http://media.test/signed-audio",
      });
    }
    if (pathContains(input, "/signed-audio")) {
      return new Response(new Uint8Array(1024), { status: 200 });
    }
    if (pathContains(input, "api.openai.com")) {
      return jsonReply({ text: "Hello world transcript." });
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        body: { message_id: MSG_ID },
        headers: { "X-Supabase-Webhook-Secret": WEBHOOK_SECRET },
      }),
    );
    assertEquals(res.status, 200);
    assertEquals(lastPatch?.transcript, "Hello world transcript.");
    assertEquals(lastPatch?.transcript_status, "ready");
  } finally {
    restore();
  }
});
