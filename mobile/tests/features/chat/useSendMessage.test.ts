jest.mock('~/lib/supabase/client', () => ({
  supabase: { from: jest.fn(), rpc: jest.fn() },
}));
// SessionContext transitively pulls in expo-linking via the auth redirect
// helper, which crashes in jest without an expo-constants manifest. Stub the
// surface so importing the hook module is side-effect-free.
jest.mock('~/features/auth/SessionContext', () => ({
  useAuthSession: () => ({ session: null }),
}));

import { supabase } from '~/lib/supabase/client';
import { newMessageId } from '~/features/chat/hooks/useSendMessage';
import { sendMessage } from '~/features/chat/services/chat.service';

// RFC 4122 v4 UUID: 8-4-4-4-12 hex, with `4` pinned in the time_hi_and_version
// nibble and one of [89ab] in the high nibble of clock_seq_hi_and_reserved.
const UUID_V4_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

describe('newMessageId', () => {
  // Save & restore the global crypto so we can exercise both code paths without
  // leaking state across tests (Hermes / jsdom hold a real implementation we
  // must put back).
  const realCrypto = globalThis.crypto;

  afterEach(() => {
    Object.defineProperty(globalThis, 'crypto', {
      value: realCrypto,
      configurable: true,
      writable: true,
    });
  });

  it('produces a valid RFC 4122 v4 UUID via crypto.randomUUID when available', () => {
    // jsdom (jest-expo's test env) provides a real Web Crypto, so this hits
    // the fast path. The shape check is the load-bearing assertion —
    // messages.id is a `uuid` column and a non-UUID id triggers Postgres
    // 22P02 on INSERT.
    const id = newMessageId();
    expect(id).toMatch(UUID_V4_RE);
  });

  it('falls back to a manually constructed v4 UUID when crypto.randomUUID is absent', () => {
    // Older JSCore environments (pre-Hermes RN, some Node versions) don't
    // expose `randomUUID`; the fallback path MUST still emit a valid v4
    // (correct version + variant nibbles) so the server INSERT doesn't fail
    // with 22P02 invalid-text-representation on the uuid column.
    Object.defineProperty(globalThis, 'crypto', {
      value: { randomUUID: undefined },
      configurable: true,
      writable: true,
    });

    for (let i = 0; i < 32; i += 1) {
      const id = newMessageId();
      expect(id).toMatch(UUID_V4_RE);
    }
  });

  it('produces unique ids across consecutive calls', () => {
    const seen = new Set<string>();
    for (let i = 0; i < 64; i += 1) seen.add(newMessageId());
    expect(seen.size).toBe(64);
  });
});

describe('sendMessage payload (kind: text)', () => {
  beforeEach(() => jest.clearAllMocks());

  it('includes kind:"text" in the INSERT payload as defence against the RLS pin', async () => {
    // The messages_insert_participant RLS WITH CHECK pins direct client
    // INSERTs to kind='text' (image/voice go through dedicated RPCs). The
    // service explicitly sends kind so a future default change can't break
    // the client silently.
    const row = { id: 'm1', body: 'hi', kind: 'text' };
    const single = jest.fn().mockResolvedValueOnce({ data: row, error: null });
    const select = jest.fn().mockReturnValue({ single });
    const insert = jest.fn().mockReturnValue({ select });
    (supabase.from as jest.Mock).mockReturnValue({ insert });

    const id = newMessageId();
    await sendMessage({ id, conversationId: 'c1', senderId: 'u1', body: 'hi' });

    expect(insert).toHaveBeenCalledWith(
      expect.objectContaining({ id, kind: 'text', body: 'hi' })
    );
  });
});
