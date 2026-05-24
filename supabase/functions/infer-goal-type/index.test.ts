// Deno tests for the infer-goal-type edge function.
//
// Run from repo root:
//   deno test --allow-net --allow-env --allow-read supabase/functions/infer-goal-type/
//
// The handler is dynamically imported AFTER env stubs + fetch mock are set,
// because `index.ts` calls `requireEnv` at module load.

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
// Module load — must come AFTER env stubs so requireEnv() succeeds.
const { handler } = await import("./index.ts");

// --- Helpers --------------------------------------------------------------

const VALID_TEXT =
  "Looking to hire a senior backend engineer for our growing startup team";

function makeAuthedRequest(body: unknown): Request {
  return makeRequest("http://x/", {
    method: "POST",
    body,
    headers: { Authorization: "Bearer fake-user-jwt" },
  });
}

// Reply for supabase-js auth.getUser — shaped like the /auth/v1/user endpoint.
function authedUserReply(): Response {
  return jsonReply({
    id: "11111111-1111-1111-1111-111111111111",
    aud: "authenticated",
    role: "authenticated",
    email: "user@test",
  });
}

// Reply that mimics the /auth/v1/user endpoint returning "no user" (401).
function unauthedUserReply(): Response {
  return jsonReply({ msg: "invalid jwt" }, 401);
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
        body: { text: VALID_TEXT, primary_role: null, roles: [] },
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
    const res = await handler(
      makeAuthedRequest({ text: VALID_TEXT, primary_role: null, roles: [] }),
    );
    assertEquals(res.status, 401);
    const j = await res.json();
    assertEquals(j.error, "unauthenticated");
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
    const j = await res.json();
    assertEquals(j.error, "invalid_body");
  } finally {
    restore();
  }
});

Deno.test("returns 400 when text is too short (< 20 chars)", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeAuthedRequest({ text: "too short", primary_role: null, roles: [] }),
    );
    assertEquals(res.status, 400);
    const j = await res.json();
    assertEquals(j.error, "invalid_body");
  } finally {
    restore();
  }
});

Deno.test("returns 400 when text is too long (> 280 chars)", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeAuthedRequest({
        text: "x".repeat(281),
        primary_role: null,
        roles: [],
      }),
    );
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});

Deno.test("returns 400 when body shape is wrong (missing text)", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeAuthedRequest({ primary_role: null, roles: [] }),
    );
    assertEquals(res.status, 400);
  } finally {
    restore();
  }
});

Deno.test("happy path: model returns 'hire' → high confidence", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    if (pathContains(input, "api.anthropic.com")) {
      return claudeReply("hire");
    }
    return jsonReply({ error: "unexpected", url: String(input) }, 599);
  });
  try {
    const res = await handler(
      makeAuthedRequest({
        text: VALID_TEXT,
        primary_role: "founder",
        roles: ["founder"],
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.goal_type, "hire");
    assertEquals(j.confidence, "high");
  } finally {
    restore();
  }
});

Deno.test("trims + lowercases model output before enum match", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    if (pathContains(input, "api.anthropic.com")) {
      return claudeReply("  INVEST  \n");
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeAuthedRequest({
        text: VALID_TEXT,
        primary_role: "investor",
        roles: ["investor"],
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.goal_type, "invest");
    assertEquals(j.confidence, "high");
  } finally {
    restore();
  }
});

Deno.test("model returns 'none' → null + low confidence", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    if (pathContains(input, "api.anthropic.com")) return claudeReply("none");
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeAuthedRequest({ text: VALID_TEXT, primary_role: null, roles: [] }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.goal_type, null);
    assertEquals(j.confidence, "low");
  } finally {
    restore();
  }
});

Deno.test("model returns garbage → null + low confidence", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    if (pathContains(input, "api.anthropic.com")) {
      return claudeReply("I'm not sure, perhaps hire or peer_connect");
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeAuthedRequest({ text: VALID_TEXT, primary_role: null, roles: [] }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.goal_type, null);
    assertEquals(j.confidence, "low");
  } finally {
    restore();
  }
});

Deno.test("returns 500 when ANTHROPIC_API_KEY is missing", async () => {
  // Drop the env var and force a fresh module import so the missing-key
  // branch is hit. Use a cache-busting suffix so Deno re-evaluates the module.
  Deno.env.delete("ANTHROPIC_API_KEY");
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) return authedUserReply();
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    // Re-import a fresh copy of the handler with no API key set.
    const mod = await import(`./index.ts?missingkey=${Date.now()}`);
    const res = await mod.handler(
      makeAuthedRequest({ text: VALID_TEXT, primary_role: null, roles: [] }),
    );
    assertEquals(res.status, 500);
    const j = await res.json();
    assertEquals(j.error, "server_misconfigured");
  } finally {
    restore();
    // Restore the env so subsequent tests in the same process see the key.
    Deno.env.set("ANTHROPIC_API_KEY", "sk-ant-test-key");
  }
});
