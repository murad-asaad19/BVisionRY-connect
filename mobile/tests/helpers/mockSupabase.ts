/**
 * Minimal Supabase client mock for service / hook tests. Implements the
 * fluent query chain (`.from(t).select().eq().single()`), the `rpc` and
 * `functions.invoke` surfaces, and a partial `auth` namespace.
 *
 * Each chain method returns the same `chain` proxy so callers can keep
 * stacking filters without the test needing to know which filter the
 * service uses. Final-call methods (`.single()`, `.maybeSingle()`) resolve
 * with the canned `resp` passed to `mockSupabaseFrom`. The chain is itself
 * thenable so `await supabase.from(t).select()…` resolves the same way.
 */

export type MockResp<T> = { data: T | null; error: { message: string; code?: string } | null };

export function mockSupabaseFrom<T>(resp: MockResp<T>) {
  const chain: Record<string, unknown> = {};
  const passthrough = [
    'select',
    'eq',
    'neq',
    'in',
    'is',
    'gt',
    'gte',
    'lt',
    'lte',
    'or',
    'and',
    'not',
    'contains',
    'overlaps',
    'order',
    'limit',
    'range',
    'insert',
    'update',
    'delete',
    'upsert',
    'match',
  ];
  for (const m of passthrough) {
    chain[m] = jest.fn(() => chain);
  }
  chain.single = jest.fn().mockResolvedValue(resp);
  chain.maybeSingle = jest.fn().mockResolvedValue(resp);
  chain.then = (onFulfilled: (r: MockResp<T>) => unknown) => Promise.resolve(resp).then(onFulfilled);
  return chain as { [k: string]: jest.Mock } & PromiseLike<MockResp<T>>;
}

/**
 * Build a full `supabase` mock keyed by table. Anything not configured falls
 * back to `{ data: null, error: null }` so unrelated reads in the service
 * under test don't blow up.
 */
export function makeMockSupabase(
  perTable: Record<string, MockResp<unknown>> = {},
  rpcResp: MockResp<unknown> = { data: null, error: null }
) {
  return {
    from: jest.fn((table: string) =>
      mockSupabaseFrom(perTable[table] ?? { data: null, error: null })
    ),
    rpc: jest.fn().mockResolvedValue(rpcResp),
    auth: {
      getUser: jest
        .fn()
        .mockResolvedValue({ data: { user: { id: 'u1', email: 'a@b.c' } }, error: null }),
      getSession: jest.fn().mockResolvedValue({ data: { session: null }, error: null }),
      onAuthStateChange: jest.fn(() => ({
        data: { subscription: { unsubscribe: jest.fn() } },
      })),
      signOut: jest.fn().mockResolvedValue({ error: null }),
      signInWithPassword: jest.fn().mockResolvedValue({ data: { session: null }, error: null }),
      signUp: jest.fn().mockResolvedValue({ data: { session: null }, error: null }),
      signInWithOtp: jest.fn().mockResolvedValue({ data: null, error: null }),
    },
    functions: { invoke: jest.fn().mockResolvedValue({ data: null, error: null }) },
    storage: {
      from: jest.fn(() => ({
        upload: jest.fn().mockResolvedValue({ data: { path: 'p' }, error: null }),
        getPublicUrl: jest.fn(() => ({ data: { publicUrl: 'https://example/p' } })),
        createSignedUrl: jest
          .fn()
          .mockResolvedValue({ data: { signedUrl: 'https://example/signed' }, error: null }),
      })),
    },
  };
}
