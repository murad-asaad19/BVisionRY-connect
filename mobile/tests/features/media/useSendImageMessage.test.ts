/**
 * Coverage for the `useSendImageMessage` hook.
 *
 * Atomicity contract:
 *   1. Pick + downscale the image (mocked).
 *   2. Upload to storage (mocked).
 *   3. Call `send_image_message` RPC with the canonical args.
 *   4. On RPC success → invalidate `['messages', conversationId]` +
 *      `['conversations']`.
 *   5. On RPC failure → throw (the orphan storage object is left in place
 *      by design; the hook only guards the message row).
 */

const mockSupabaseRpc = jest.fn();
jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: (...args: unknown[]) => mockSupabaseRpc(...args) },
}));

const mockPickImage = jest.fn();
jest.mock('~/features/media/hooks/usePickImage', () => ({
  pickImage: (...args: unknown[]) => mockPickImage(...args),
}));

const mockUploadChatMedia = jest.fn();
jest.mock('~/features/media/services/storage.service', () => ({
  uploadChatMedia: (...args: unknown[]) => mockUploadChatMedia(...args),
}));

// Mutable container so individual tests can null-out the session.
const mockSessionRef: { session: { user: { id: string } } | null } = {
  session: { user: { id: 'u1' } },
};
jest.mock('~/features/auth/SessionContext', () => ({
  useAuthSession: () => mockSessionRef,
}));

// `generateUuid` is wrapped so each test gets a deterministic id.
jest.mock('~/features/media/services/media.constants', () => {
  const actual = jest.requireActual('~/features/media/services/media.constants');
  return {
    ...actual,
    generateUuid: jest.fn(() => 'msg-uuid-1'),
  };
});

jest.mock('expo-file-system', () => ({
  File: jest.fn().mockImplementation(() => ({ exists: false, delete: jest.fn() })),
}));

import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { act, renderHook } from '@testing-library/react-native';

import { useSendImageMessage } from '~/features/media/hooks/useSendImageMessage';

function wrapWithClient(qc: QueryClient) {
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return React.createElement(QueryClientProvider, { client: qc }, children);
  };
}

const CONV_ID = 'conv-1';
// `pickImage` now returns raw bytes (Uint8Array) instead of a lazy Blob — the
// blob path uploaded as 0 bytes on React Native via XHR. See useSendImageMessage.
const picked = {
  uri: 'file:///tmp/img.jpg',
  width: 1200,
  height: 1200,
  bytes: new Uint8Array(12345),
  size: 12345,
  ext: 'jpg' as const,
};

describe('useSendImageMessage', () => {
  let qc: QueryClient;

  beforeEach(() => {
    jest.clearAllMocks();
    qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  });
  afterEach(() => qc.clear());

  it('uploads then calls send_image_message with the canonical args and invalidates caches', async () => {
    mockPickImage.mockResolvedValueOnce(picked);
    mockUploadChatMedia.mockResolvedValueOnce('conv-1/msg-uuid-1/msg-uuid-1.jpg');
    mockSupabaseRpc.mockResolvedValueOnce({ data: { id: 'msg-uuid-1' }, error: null });
    const invalidateSpy = jest.spyOn(qc, 'invalidateQueries');

    const { result } = renderHook(() => useSendImageMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });
    let returned: string | null | undefined;
    await act(async () => {
      returned = await result.current.mutateAsync();
    });

    expect(mockUploadChatMedia).toHaveBeenCalledWith(
      CONV_ID,
      'msg-uuid-1',
      picked.bytes,
      'jpg',
      'image/jpeg',
      'msg-uuid-1.jpg'
    );
    expect(mockSupabaseRpc).toHaveBeenCalledWith('send_image_message', {
      p_conversation_id: CONV_ID,
      p_media_path: 'conv-1/msg-uuid-1/msg-uuid-1.jpg',
      p_media_mime: 'image/jpeg',
      p_media_size_bytes: 12345,
    });
    expect(returned).toBe('msg-uuid-1');
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['messages', CONV_ID] });
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['conversations'] });
  });

  it('returns null and skips the RPC when the user cancels the picker', async () => {
    mockPickImage.mockResolvedValueOnce(null);

    const { result } = renderHook(() => useSendImageMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });
    let returned: string | null | undefined;
    await act(async () => {
      returned = await result.current.mutateAsync();
    });

    expect(returned).toBeNull();
    expect(mockUploadChatMedia).not.toHaveBeenCalled();
    expect(mockSupabaseRpc).not.toHaveBeenCalled();
  });

  it('throws "not signed in" before touching storage when there is no session', async () => {
    const original = mockSessionRef.session;
    mockSessionRef.session = null;

    const { result } = renderHook(() => useSendImageMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });
    await act(async () => {
      await expect(result.current.mutateAsync()).rejects.toThrow('not signed in');
    });
    expect(mockPickImage).not.toHaveBeenCalled();
    expect(mockUploadChatMedia).not.toHaveBeenCalled();

    mockSessionRef.session = original;
  });

  it('throws when the RPC errors and does NOT invalidate caches', async () => {
    mockPickImage.mockResolvedValueOnce(picked);
    mockUploadChatMedia.mockResolvedValueOnce('conv-1/msg-uuid-1/msg-uuid-1.jpg');
    mockSupabaseRpc.mockResolvedValueOnce({ data: null, error: { message: 'rls denied' } });
    const invalidateSpy = jest.spyOn(qc, 'invalidateQueries');

    const { result } = renderHook(() => useSendImageMessage(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });
    await act(async () => {
      await expect(result.current.mutateAsync()).rejects.toThrow('rls denied');
    });

    // Upload happened (orphan storage object is intentional), but no cache
    // invalidation should fire because the mutation threw.
    expect(mockUploadChatMedia).toHaveBeenCalled();
    expect(invalidateSpy).not.toHaveBeenCalled();
  });
});
