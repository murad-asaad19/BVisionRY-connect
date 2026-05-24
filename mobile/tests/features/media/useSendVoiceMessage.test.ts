/**
 * Coverage for the `useSendVoiceMessage` hook.
 *
 * Atomicity contract:
 *   1. Validate duration + size (Alert.alert short-circuits on overflow).
 *   2. Upload to storage.
 *   3. Call `send_voice_message` RPC with the canonical args + duration.
 *   4. On success → invalidate `['messages', conversationId]` +
 *      `['conversations']`.
 *   5. On RPC failure → throw (orphan storage object is left in place).
 */

const mockSupabaseRpc = jest.fn();
jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: (...args: unknown[]) => mockSupabaseRpc(...args) },
}));

const mockUploadChatMedia = jest.fn();
jest.mock('~/features/media/services/storage.service', () => ({
  uploadChatMedia: (...args: unknown[]) => mockUploadChatMedia(...args),
}));

const mockSessionRef: { session: { user: { id: string } } | null } = {
  session: { user: { id: 'u1' } },
};
jest.mock('~/features/auth/SessionContext', () => ({
  useAuthSession: () => mockSessionRef,
}));

jest.mock('~/features/media/services/media.constants', () => {
  const actual = jest.requireActual('~/features/media/services/media.constants');
  return {
    ...actual,
    generateUuid: jest.fn(() => 'msg-uuid-2'),
  };
});

jest.mock('expo-file-system', () => ({
  File: jest.fn().mockImplementation(() => ({ exists: false, delete: jest.fn() })),
}));

jest.mock('~/lib/i18n', () => ({
  i18n: { t: (k: string) => k },
}));

import { Alert } from 'react-native';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { act, renderHook } from '@testing-library/react-native';

import { useSendVoiceMessage } from '~/features/media/hooks/useSendVoiceMessage';
import { MAX_VOICE_MS, MAX_VOICE_BYTES } from '~/features/media/services/media.constants';

function wrapWithClient(qc: QueryClient) {
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return React.createElement(QueryClientProvider, { client: qc }, children);
  };
}

const CONV_ID = 'conv-1';

function stubFetchWithBlob(size: number) {
  global.fetch = jest.fn().mockResolvedValue({ blob: async () => ({ size }) }) as typeof fetch;
}

describe('useSendVoiceMessage', () => {
  let qc: QueryClient;
  let alertSpy: jest.SpyInstance;
  const realFetch = global.fetch;

  beforeEach(() => {
    jest.clearAllMocks();
    qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    alertSpy = jest.spyOn(Alert, 'alert').mockImplementation(() => {});
  });
  afterEach(() => {
    qc.clear();
    alertSpy.mockRestore();
    global.fetch = realFetch;
  });

  it('uploads then calls send_voice_message with the canonical args and invalidates caches', async () => {
    stubFetchWithBlob(123_456);
    mockUploadChatMedia.mockResolvedValueOnce('conv-1/msg-uuid-2/msg-uuid-2.m4a');
    mockSupabaseRpc.mockResolvedValueOnce({ data: { id: 'msg-uuid-2' }, error: null });
    const invalidateSpy = jest.spyOn(qc, 'invalidateQueries');

    const { result } = renderHook(() => useSendVoiceMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    let returned: string | null | undefined;
    await act(async () => {
      returned = await result.current.mutateAsync({
        uri: 'file:///tmp/rec.m4a',
        durationMs: 5_000,
      });
    });

    expect(mockUploadChatMedia).toHaveBeenCalledWith(
      CONV_ID,
      'msg-uuid-2',
      expect.objectContaining({ size: 123_456 }),
      'm4a',
      'audio/m4a',
      'msg-uuid-2.m4a'
    );
    expect(mockSupabaseRpc).toHaveBeenCalledWith('send_voice_message', {
      p_conversation_id: CONV_ID,
      p_media_path: 'conv-1/msg-uuid-2/msg-uuid-2.m4a',
      p_media_mime: 'audio/m4a',
      p_media_size_bytes: 123_456,
      p_duration_ms: 5_000,
    });
    expect(returned).toBe('msg-uuid-2');
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['messages', CONV_ID] });
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['conversations'] });
  });

  it('short-circuits with an Alert when duration exceeds MAX_VOICE_MS', async () => {
    const { result } = renderHook(() => useSendVoiceMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    let returned: string | null | undefined;
    await act(async () => {
      returned = await result.current.mutateAsync({
        uri: 'file:///tmp/long.m4a',
        durationMs: MAX_VOICE_MS + 1,
      });
    });

    expect(returned).toBeNull();
    expect(alertSpy).toHaveBeenCalled();
    expect(mockUploadChatMedia).not.toHaveBeenCalled();
    expect(mockSupabaseRpc).not.toHaveBeenCalled();
  });

  it('short-circuits with an Alert when blob exceeds MAX_VOICE_BYTES', async () => {
    stubFetchWithBlob(MAX_VOICE_BYTES + 1);

    const { result } = renderHook(() => useSendVoiceMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    let returned: string | null | undefined;
    await act(async () => {
      returned = await result.current.mutateAsync({
        uri: 'file:///tmp/big.m4a',
        durationMs: 5_000,
      });
    });

    expect(returned).toBeNull();
    expect(alertSpy).toHaveBeenCalled();
    expect(mockUploadChatMedia).not.toHaveBeenCalled();
    expect(mockSupabaseRpc).not.toHaveBeenCalled();
  });

  it('throws "not signed in" before any I/O when there is no session', async () => {
    const original = mockSessionRef.session;
    mockSessionRef.session = null;

    const { result } = renderHook(() => useSendVoiceMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    await act(async () => {
      await expect(
        result.current.mutateAsync({ uri: 'file:///tmp/x.m4a', durationMs: 5_000 })
      ).rejects.toThrow('not signed in');
    });

    expect(mockUploadChatMedia).not.toHaveBeenCalled();
    mockSessionRef.session = original;
  });

  it('throws when the RPC errors and does NOT invalidate caches', async () => {
    stubFetchWithBlob(50_000);
    mockUploadChatMedia.mockResolvedValueOnce('conv-1/msg-uuid-2/msg-uuid-2.m4a');
    mockSupabaseRpc.mockResolvedValueOnce({ data: null, error: { message: 'rls denied' } });
    const invalidateSpy = jest.spyOn(qc, 'invalidateQueries');

    const { result } = renderHook(() => useSendVoiceMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });
    await act(async () => {
      await expect(
        result.current.mutateAsync({ uri: 'file:///tmp/rec.m4a', durationMs: 5_000 })
      ).rejects.toThrow('rls denied');
    });

    expect(mockUploadChatMedia).toHaveBeenCalled();
    expect(invalidateSpy).not.toHaveBeenCalled();
  });
});
