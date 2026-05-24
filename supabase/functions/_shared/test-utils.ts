// Test helpers shared across edge function unit tests.
//
// Design goal: each test file is fully isolated. We can't easily stub
// `createClient` because the production handlers call it at module-load time
// (admin = createClient(...)). Instead we intercept `globalThis.fetch` — which
// supabase-js, the FCM client, and Whisper all ultimately go through — and
// answer with canned Response objects.
//
// Pattern in each test:
//
//   import { mockFetch, setStubEnv } from "../_shared/test-utils.ts";
//   setStubEnv({ SUPABASE_URL: "http://test", SUPABASE_SERVICE_ROLE_KEY: "..." });
//   const { handler } = await import("./index.ts");  // dynamic import AFTER env+stub
//   const restore = mockFetch((url, init) => { ... });
//   try { ... } finally { restore(); }

export type FetchHandler = (
  input: string | URL | Request,
  init?: RequestInit,
) => Response | Promise<Response>;

/**
 * Replace globalThis.fetch with the given handler for the duration of the
 * returned function. Returns a `restore()` that puts the original fetch back —
 * call it in a finally block.
 *
 * The handler can be a fall-through router: return new Response('not mocked',
 * { status: 599 }) for unexpected URLs so the test fails loudly instead of
 * leaking real network calls.
 */
export function mockFetch(handler: FetchHandler): () => void {
  const original = globalThis.fetch;
  globalThis.fetch = ((
    input: RequestInfo | URL,
    init?: RequestInit,
  ): Promise<Response> => {
    const url = typeof input === "string" || input instanceof URL
      ? input
      : (input as Request).url;
    return Promise.resolve(handler(url as string | URL | Request, init));
  }) as typeof fetch;
  return () => {
    globalThis.fetch = original;
  };
}

/**
 * Set env vars BEFORE the handler module is imported. The handlers' top-level
 * requireEnv() calls otherwise throw at import time.
 */
export function setStubEnv(vars: Record<string, string>): void {
  for (const [k, v] of Object.entries(vars)) {
    Deno.env.set(k, v);
  }
}

/**
 * Convenience: a minimal valid env that satisfies requireEnv across all four
 * webhook-style functions. Tests may override or augment via setStubEnv.
 */
export function setDefaultEnv(): void {
  setStubEnv({
    SUPABASE_URL: "http://supabase.test",
    SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    SUPABASE_ANON_KEY: "test-anon-key",
    WEBHOOK_SHARED_SECRET: "test-webhook-secret",
  });
}

/** Build a JSON Response for use as a mock fetch reply. */
export function jsonReply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/**
 * Build a Request to pass into the handler. Defaults to POST + JSON content.
 * Pass `null` for body to omit it.
 */
export function makeRequest(
  url = "http://test.local/",
  init: {
    method?: string;
    body?: unknown;
    headers?: Record<string, string>;
  } = {},
): Request {
  const method = init.method ?? "POST";
  const headers = new Headers(init.headers ?? {});
  let body: BodyInit | undefined;
  if (init.body !== undefined && init.body !== null) {
    if (typeof init.body === "string") {
      body = init.body;
    } else {
      body = JSON.stringify(init.body);
      if (!headers.has("Content-Type")) headers.set("Content-Type", "application/json");
    }
  }
  return new Request(url, { method, headers, body });
}

/**
 * Tiny URL matcher utility: returns true if the url's pathname contains the
 * given fragment. Use inside a fetch router branch.
 */
export function pathContains(
  input: string | URL | Request,
  fragment: string,
): boolean {
  const s = typeof input === "string"
    ? input
    : input instanceof URL
      ? input.toString()
      : (input as Request).url;
  return s.includes(fragment);
}
