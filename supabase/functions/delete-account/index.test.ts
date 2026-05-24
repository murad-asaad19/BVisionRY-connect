// Deno tests for the delete-account edge function.

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  jsonReply,
  makeRequest,
  mockFetch,
  pathContains,
  setDefaultEnv,
} from "../_shared/test-utils.ts";

setDefaultEnv();
const { handler } = await import("./index.ts");

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

Deno.test("returns 401 when Authorization header missing", async () => {
  const restore = mockFetch(() => jsonReply({ error: "unexpected" }, 599));
  try {
    const res = await handler(
      makeRequest("http://x/", { method: "POST", body: {} }),
    );
    assertEquals(res.status, 401);
    const j = await res.json();
    assertEquals(j.error, "unauthorized");
  } finally {
    restore();
  }
});

Deno.test("returns 401 when getUser() rejects the JWT", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) {
      // No user → unauthorized.
      return jsonReply({ msg: "invalid jwt" }, 401);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: {},
        headers: { Authorization: "Bearer bad-jwt" },
      }),
    );
    assertEquals(res.status, 401);
  } finally {
    restore();
  }
});

Deno.test("returns 200 + {ok:true} on success path", async () => {
  let rpcCalled = false;
  let adminDeleteCalled = false;
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/auth/v1/user")) {
      return jsonReply({
        id: "11111111-1111-1111-1111-111111111111",
        email: "alice@test.local",
      });
    }
    if (pathContains(input, "/rest/v1/rpc/delete_my_account")) {
      rpcCalled = true;
      return jsonReply(null);
    }
    if (pathContains(input, "/auth/v1/admin/users/")) {
      // DELETE on admin/users/{id}
      if ((init?.method ?? "GET").toUpperCase() === "DELETE") {
        adminDeleteCalled = true;
        return jsonReply({});
      }
    }
    return jsonReply({ error: "unexpected", url: String(input) }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: {},
        headers: { Authorization: "Bearer good-jwt" },
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.ok, true);
    assertEquals(rpcCalled, true);
    assertEquals(adminDeleteCalled, true);
  } finally {
    restore();
  }
});

Deno.test("treats 'user not found' from admin.deleteUser as success (idempotent retry)", async () => {
  const restore = mockFetch((input, init) => {
    if (pathContains(input, "/auth/v1/user")) {
      return jsonReply({
        id: "11111111-1111-1111-1111-111111111111",
      });
    }
    if (pathContains(input, "/rest/v1/rpc/delete_my_account")) {
      return jsonReply(null);
    }
    if (
      pathContains(input, "/auth/v1/admin/users/") &&
      (init?.method ?? "").toUpperCase() === "DELETE"
    ) {
      // GoTrue returns 404 / "user not found" when re-deleting a wiped user.
      return jsonReply({ msg: "User not found", code: "user_not_found" }, 404);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: {},
        headers: { Authorization: "Bearer good-jwt" },
      }),
    );
    assertEquals(res.status, 200);
    const j = await res.json();
    assertEquals(j.ok, true);
  } finally {
    restore();
  }
});

Deno.test("returns 500 when delete_my_account RPC fails", async () => {
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) {
      return jsonReply({ id: "11111111-1111-1111-1111-111111111111" });
    }
    if (pathContains(input, "/rest/v1/rpc/delete_my_account")) {
      return jsonReply({ message: "boom" }, 500);
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: {},
        headers: { Authorization: "Bearer good-jwt" },
      }),
    );
    assertEquals(res.status, 500);
  } finally {
    restore();
  }
});

Deno.test("does not leak service-role key in response body or error text", async () => {
  // Stash the service-role key from env, then make sure no response body
  // includes it. This is a paranoia check — the function never echos env.
  const SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const restore = mockFetch((input) => {
    if (pathContains(input, "/auth/v1/user")) {
      return jsonReply({ msg: "bad", code: SRK }, 401); // worst case: error echos srk
    }
    return jsonReply({ error: "unexpected" }, 599);
  });
  try {
    const res = await handler(
      makeRequest("http://x/", {
        method: "POST",
        body: {},
        headers: { Authorization: "Bearer junk" },
      }),
    );
    const text = await res.text();
    assertEquals(text.includes(SRK), false);
  } finally {
    restore();
  }
});
