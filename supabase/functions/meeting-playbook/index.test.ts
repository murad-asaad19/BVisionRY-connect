// Deno tests for the meeting-playbook edge function.
//
// Run from repo root:
//   deno test --allow-net --allow-env --allow-read supabase/functions/meeting-playbook/
//
// The handler is dynamically imported AFTER env stubs + fetch mock are set
// because `index.ts` calls `requireEnv` at module load.
//
// Strategy: each test sets up a small fetch router that pattern-matches the
// outgoing URL. The handler routes are:
//   * /auth/v1/user                                   — JWT resolution.
//   * /rest/v1/meeting_proposals ?id=eq.…             — meeting lookup.
//   * /rest/v1/conversations ?id=eq.…                 — participant resolution.
//   * /rest/v1/profiles ?id=in.(…)                    — display fields.
//   * /rest/v1/office_hours_slots ?meeting_proposal_id=eq.… — topic lookup.
//   * /rest/v1/meeting_playbooks ?meeting_id=eq.…&viewer_id=eq.…&select=* — cache.
//   * /rest/v1/meeting_playbooks (POST/PATCH/upsert)  — write.
//   * api.anthropic.com/v1/messages                   — generation.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  jsonReply,
  makeRequest,
  mockFetch,
  pathContains,
  setDefaultEnv,
  setStubEnv,
} from "../_shared/test-utils.ts";

setDefaultEnv();
setStubEnv({ ANTHROPIC_API_KEY: "sk-ant-test-key" });
const { handler } = await import("./index.ts");

// --- Helpers --------------------------------------------------------------

const MEETING_ID = "11111111-2222-3333-4444-555555555555";
const VIEWER_ID = "aaaaaaaa-1111-1111-1111-111111111111";
const TARGET_ID = "bbbbbbbb-2222-2222-2222-222222222222";
const CONVERSATION_ID = "cccccccc-3333-3333-3333-333333333333";

const VIEWER_PROFILE = {
  id: VIEWER_ID,
  name: "Alice",
  headline: "Engineer",
  bio: "Building things",
  roles: ["founder"],
  primary_role: "founder",
  goal_type: "co_found",
  goal_text: "Find a cofounder",
  city: "Berlin",
  country: "DE",
};
const TARGET_PROFILE = {
  id: TARGET_ID,
  name: "Bob",
  headline: "Designer",
  bio: "Crafting UX",
  roles: ["designer"],
  primary_role: "designer",
  goal_type: "peer_connect",
  goal_text: "Make friends",
  city: "Berlin",
  country: "DE",
};

const VALID_PLAYBOOK_JSON = JSON.stringify({
  summary: "Bob designs interfaces and is in Berlin.",
  shared_interests: ["Berlin tech", "Product design", "Cofounder hunt"],
  conversation_starters: [
    "What product are you working on?",
    "What got you into UX?",
    "Tell me about Berlin's design scene.",
  ],
  do_notes: ["Ask about portfolio", "Mention you're hunting cofounders"],
  dont_notes: ["Don't pitch immediately"],
});

function makeAuthedRequest(body: unknown): Request {
  return makeRequest("http://x/", {
    method: "POST",
    body,
    headers: { Authorization: "Bearer fake-user-jwt" },
  });
}

function authedUserReply(): Response {
  return jsonReply({
    id: VIEWER_ID,
    aud: "authenticated",
    role: "authenticated",
    email: "viewer@test",
  });
}

function unauthedUserReply(): Response {
  return jsonReply({ msg: "invalid jwt" }, 401);
}

function meetingReply(): Response {
  return jsonReply({
    id: MEETING_ID,
    conversation_id: CONVERSATION_ID,
    state: "confirmed",
    confirmed_slot: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
  });
}

function conversationReply(
  participants: { a: string; b: string } = {
    a: VIEWER_ID,
    b: TARGET_ID,
  },
): Response {
  return jsonReply({
    participant_a_id: participants.a,
    participant_b_id: participants.b,
  });
}

function profilesReply(): Response {
  return jsonReply([VIEWER_PROFILE, TARGET_PROFILE]);
}

function emptySlotReply(): Response {
  // .maybeSingle() expects null or single object — return null.
  return jsonReply(null);
}

function emptyCacheReply(): Response {
  return jsonReply(null);
}

function cachedRowReply(opts: {
  hash: string;
  generatedAt?: string;
  summary?: string;
}): Response {
  return jsonReply({
    summary: opts.summary ?? "cached summary",
    shared_interests: ["cached"],
    conversation_starters: ["cached q"],
    do_notes: ["cached do"],
    dont_notes: ["cached dont"],
    generated_at: opts.generatedAt ?? new Date().toISOString(),
    generation_input_hash: opts.hash,
  });
}

function claudeReply(textContent: string): Response {
  return jsonReply({
    id: "msg_test",
    type: "message",
    role: "assistant",
    model: "claude-sonnet-4-6",
    content: [{ type: "text", text: textContent }],
    stop_reason: "end_turn",
    usage: { input_tokens: 1, output_tokens: 1 },
  });
}

/**
 * Router used by the happy-path and cache-related tests. Behaviours that
 * vary per test (cache row present, anthropic response shape, …) are
 * injected via `opts`.
 */
function makeRouter(opts: {
  cache?: () => Response;
  claude?: () => Response;
  anthropicCalled?: { v: number };
  upsertedRow?: { v: unknown };
  conversation?: Response;
  slot?: () => Response;
}): (input: string | URL | Request, init?: RequestInit) => Response {
  return (input, init) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    if (pathContains(input, "api.anthropic.com")) {
      if (opts.anthropicCalled) opts.anthropicCalled.v += 1;
      return opts.claude ? opts.claude() : claudeReply(VALID_PLAYBOOK_JSON);
    }
    if (pathContains(input, "/rest/v1/meeting_proposals")) {
      return meetingReply();
    }
    if (pathContains(input, "/rest/v1/conversations")) {
      return opts.conversation ?? conversationReply();
    }
    if (pathContains(input, "/rest/v1/profiles")) {
      return profilesReply();
    }
    if (pathContains(input, "/rest/v1/office_hours_slots")) {
      return opts.slot ? opts.slot() : emptySlotReply();
    }
    if (pathContains(input, "/rest/v1/meeting_playbooks")) {
      const method = init?.method ?? "GET";
      if (method === "GET") {
        return opts.cache ? opts.cache() : emptyCacheReply();
      }
      // POST / upsert. Capture body and ack.
      if (opts.upsertedRow) {
        try {
          opts.upsertedRow.v = init?.body ? JSON.parse(init.body as string) : null;
        } catch {
          opts.upsertedRow.v = init?.body ?? null;
        }
      }
      return jsonReply(null, 201);
    }
    return jsonReply({ error: "unexpected", url: String(input) }, 599);
  };
}

// --- Tests ----------------------------------------------------------------

Deno.test("returns 405 on GET", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(makeRequest("http://x/", { method: "GET" }));
    assertEquals(res.status, 405);
  } finally {
    restore();
  }
});

Deno.test("returns 401 when no Authorization header", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: { meeting_id: MEETING_ID },
      }),
    );
    assertEquals(res.status, 401);
    const j = await res.json();
    assertEquals(j.error, "unauthenticated");
  } finally {
    restore();
  }
});

Deno.test("returns 401 when JWT does not resolve to a user", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return unauthedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
    assertEquals(res.status, 401);
  } finally {
    restore();
  }
});

Deno.test("returns 400 on invalid JSON body", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: "{not json",
        headers: {
          "Content-Type": "application/json",
          Authorization: "Bearer fake-user-jwt",
        },
      }),
    );
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});

Deno.test("returns 400 when meeting_id missing", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(makeAuthedRequest({}));
    assertEquals(res.status, 400);
    const j = await res.json();
    assertEquals(j.error, "invalid_body");
  } finally {
    restore();
  }
});

Deno.test("returns 400 when meeting_id is not a uuid", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(makeAuthedRequest({ meeting_id: "not-a-uuid" }));
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});

Deno.test("returns 403 when caller is not a participant", async () => {
  const anthropicCalled = { v: 0 };
  const restore = mockFetch(makeRouter({
    anthropicCalled,
    // Conversation participants don't include VIEWER_ID.
    conversation: jsonReply({
      participant_a_id: "ffffffff-ffff-ffff-ffff-ffffffffffff",
      participant_b_id: TARGET_ID,
    }),
  }));
  try {
    const res = await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
    assertEquals(res.status, 403);
    assertEquals(anthropicCalled.v, 0);
  } finally {
    restore();
  }
});

Deno.test(
  "happy path: no cached row → calls Anthropic → upserts → returns the 5 fields",
  async () => {
    const anthropicCalled = { v: 0 };
    const upserted = { v: null as unknown };
    const restore = mockFetch(makeRouter({ anthropicCalled, upsertedRow: upserted }));
    try {
      const res = await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
      assertEquals(res.status, 200);
      const j = await res.json();
      assertEquals(typeof j.summary, "string");
      assertEquals(Array.isArray(j.shared_interests), true);
      assertEquals(Array.isArray(j.conversation_starters), true);
      assertEquals(Array.isArray(j.do_notes), true);
      assertEquals(Array.isArray(j.dont_notes), true);
      assertEquals(typeof j.generated_at, "string");
      assertEquals(anthropicCalled.v, 1);
      // The upsert body should include the right keys.
      const row = upserted.v as Record<string, unknown> | null;
      assertEquals(typeof row?.meeting_id, "string");
      assertEquals(row?.viewer_id, VIEWER_ID);
      assertEquals(row?.target_id, TARGET_ID);
      assertEquals(typeof row?.generation_input_hash, "string");
    } finally {
      restore();
    }
  },
);

Deno.test("cache hit: matching hash + < 7d old → no Anthropic call", async () => {
  // Compute the canonical hash inputs the handler will see. We need to
  // match its stableStringify(...) of {viewer_profile, target_profile,
  // meeting_topic} — easier path: capture the upsert hash from a first
  // (non-cache) call, then feed it back as the cache row's hash.
  const firstUpserted = { v: null as unknown };
  let restore = mockFetch(makeRouter({ upsertedRow: firstUpserted }));
  await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
  restore();
  const hash =
    (firstUpserted.v as { generation_input_hash?: string } | null)
      ?.generation_input_hash ?? "missing";

  const anthropicCalled = { v: 0 };
  restore = mockFetch(makeRouter({
    anthropicCalled,
    cache: () =>
      cachedRowReply({
        hash,
        generatedAt: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
        summary: "cached summary",
      }),
  }));
  try {
    const res = await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.summary, "cached summary");
    assertEquals(anthropicCalled.v, 0);
  } finally {
    restore();
  }
});

Deno.test("cache miss by hash drift → regenerates", async () => {
  const anthropicCalled = { v: 0 };
  const restore = mockFetch(makeRouter({
    anthropicCalled,
    cache: () =>
      cachedRowReply({
        hash: "stale-hash",
        generatedAt: new Date().toISOString(),
      }),
  }));
  try {
    const res = await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
    assertEquals(res.status, 200);
    assertEquals(anthropicCalled.v, 1);
  } finally {
    restore();
  }
});

Deno.test("cache miss by age > 7d → regenerates", async () => {
  // Compute the hash the handler would see (so the only stale axis is age).
  const firstUpserted = { v: null as unknown };
  let restore = mockFetch(makeRouter({ upsertedRow: firstUpserted }));
  await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
  restore();
  const hash =
    (firstUpserted.v as { generation_input_hash?: string } | null)
      ?.generation_input_hash ?? "missing";

  const anthropicCalled = { v: 0 };
  restore = mockFetch(makeRouter({
    anthropicCalled,
    cache: () =>
      cachedRowReply({
        hash,
        generatedAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
      }),
  }));
  try {
    const res = await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
    assertEquals(res.status, 200);
    assertEquals(anthropicCalled.v, 1);
  } finally {
    restore();
  }
});

Deno.test("force: true → regenerates even when cache is fresh + hash matches", async () => {
  const firstUpserted = { v: null as unknown };
  let restore = mockFetch(makeRouter({ upsertedRow: firstUpserted }));
  await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
  restore();
  const hash =
    (firstUpserted.v as { generation_input_hash?: string } | null)
      ?.generation_input_hash ?? "missing";

  const anthropicCalled = { v: 0 };
  restore = mockFetch(makeRouter({
    anthropicCalled,
    cache: () =>
      cachedRowReply({
        hash,
        generatedAt: new Date().toISOString(),
      }),
  }));
  try {
    const res = await handler(
      makeAuthedRequest({ meeting_id: MEETING_ID, force: true }),
    );
    assertEquals(res.status, 200);
    assertEquals(anthropicCalled.v, 1);
  } finally {
    restore();
  }
});

Deno.test(
  "returns 502 when Anthropic returns garbage JSON — no row written",
  async () => {
    const upserted = { v: null as unknown };
    let upsertAttempted = 0;
    const restore = mockFetch((input, init) => {
      if (pathContains(input, "/auth/v1/user")) return authedUserReply();
      if (pathContains(input, "api.anthropic.com")) {
        return claudeReply("not json at all — sorry");
      }
      if (pathContains(input, "/rest/v1/meeting_proposals")) return meetingReply();
      if (pathContains(input, "/rest/v1/conversations")) return conversationReply();
      if (pathContains(input, "/rest/v1/profiles")) return profilesReply();
      if (pathContains(input, "/rest/v1/office_hours_slots")) return emptySlotReply();
      if (pathContains(input, "/rest/v1/meeting_playbooks")) {
        const method = init?.method ?? "GET";
        if (method === "GET") return emptyCacheReply();
        upsertAttempted += 1;
        upserted.v = init?.body ?? null;
        return jsonReply(null, 201);
      }
      return jsonReply({ error: "unexpected" }, 599);
    });
    try {
      const res = await handler(makeAuthedRequest({ meeting_id: MEETING_ID }));
      assertEquals(res.status, 502);
      const j = await res.json();
      assertEquals(j.error, "generation_failed");
      // The handler must NOT have attempted to upsert a row.
      assertEquals(upsertAttempted, 0);
      assertEquals(upserted.v, null);
    } finally {
      restore();
    }
  },
);

Deno.test("returns 500 when ANTHROPIC_API_KEY is missing on a cache miss", async () => {
  Deno.env.delete("ANTHROPIC_API_KEY");
  const restore = mockFetch(makeRouter({}));
  try {
    const mod = await import(`./index.ts?missingkey=${Date.now()}`);
    const res = await mod.handler(
      makeAuthedRequest({ meeting_id: MEETING_ID }),
    );
    assertEquals(res.status, 500);
    const j = await res.json();
    assertEquals(j.error, "server_misconfigured");
  } finally {
    restore();
    Deno.env.set("ANTHROPIC_API_KEY", "sk-ant-test-key");
  }
});
