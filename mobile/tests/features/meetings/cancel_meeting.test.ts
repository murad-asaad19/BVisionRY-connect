/**
 * Coverage for the `useCancelMeeting` hook.
 *
 * The hook calls `cancelMeeting(meetingId)` (proposer-only RPC) and on
 * success:
 *   1. Replaces the cached row in `['meeting-proposals', conversationId]`
 *      with the returned row.
 *   2. Invalidates `['messages', conversationId]` so the in-thread bubble
 *      re-renders with the new state.
 *
 * The service is mocked at module level so the test never touches Supabase.
 */

const mockCancelMeeting = jest.fn();
jest.mock('~/features/meetings/services/meetings.service', () => ({
  cancelMeeting: (...args: unknown[]) => mockCancelMeeting(...args),
}));

import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { act, renderHook, waitFor } from '@testing-library/react-native';

import { useCancelMeeting } from '~/features/meetings/hooks/useCancelMeeting';

function wrapWithClient(qc: QueryClient) {
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return React.createElement(QueryClientProvider, { client: qc }, children);
  };
}

const CONV_ID = 'conv-1';

const seedRow = {
  id: 'mp1',
  conversation_id: CONV_ID,
  proposed_by_id: 'u1',
  state: 'proposed',
  slots: ['2030-01-01T00:00:00Z'],
  confirmed_slot: null,
  duration_minutes: 30,
  meeting_url: null,
  timezone: 'UTC',
  created_at: '2030-01-01T00:00:00Z',
  updated_at: '2030-01-01T00:00:00Z',
};

const cancelledRow = { ...seedRow, state: 'cancelled' };

describe('useCancelMeeting', () => {
  let qc: QueryClient;

  beforeEach(() => {
    jest.clearAllMocks();
    qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  });
  afterEach(() => qc.clear());

  it('invokes cancelMeeting with the supplied id', async () => {
    mockCancelMeeting.mockResolvedValueOnce(cancelledRow);

    const { result } = renderHook(() => useCancelMeeting(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    await act(async () => {
      await result.current.mutateAsync('mp1');
    });

    expect(mockCancelMeeting).toHaveBeenCalledWith('mp1');
  });

  it('replaces the cached proposal row on success', async () => {
    qc.setQueryData(['meeting-proposals', CONV_ID], [seedRow]);
    mockCancelMeeting.mockResolvedValueOnce(cancelledRow);

    const { result } = renderHook(() => useCancelMeeting(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    await act(async () => {
      await result.current.mutateAsync('mp1');
    });

    await waitFor(() => {
      const cached = qc.getQueryData(['meeting-proposals', CONV_ID]);
      expect(cached).toEqual([cancelledRow]);
    });
  });

  it('seeds the proposal cache when none existed yet', async () => {
    mockCancelMeeting.mockResolvedValueOnce(cancelledRow);

    const { result } = renderHook(() => useCancelMeeting(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    await act(async () => {
      await result.current.mutateAsync('mp1');
    });

    await waitFor(() => {
      const cached = qc.getQueryData(['meeting-proposals', CONV_ID]);
      expect(cached).toEqual([cancelledRow]);
    });
  });

  it('invalidates the messages cache for the same conversation on success', async () => {
    const invalidateSpy = jest.spyOn(qc, 'invalidateQueries');
    mockCancelMeeting.mockResolvedValueOnce(cancelledRow);

    const { result } = renderHook(() => useCancelMeeting(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    await act(async () => {
      await result.current.mutateAsync('mp1');
    });

    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['messages', CONV_ID] });
  });

  it('does not touch caches when the RPC throws', async () => {
    qc.setQueryData(['meeting-proposals', CONV_ID], [seedRow]);
    const invalidateSpy = jest.spyOn(qc, 'invalidateQueries');
    mockCancelMeeting.mockRejectedValueOnce(new Error('only proposer can cancel'));

    const { result } = renderHook(() => useCancelMeeting(CONV_ID), {
      wrapper: wrapWithClient(qc),
    });

    await act(async () => {
      await expect(result.current.mutateAsync('mp1')).rejects.toThrow('only proposer can cancel');
    });

    // Cache is unchanged + no message invalidation fired.
    expect(qc.getQueryData(['meeting-proposals', CONV_ID])).toEqual([seedRow]);
    expect(invalidateSpy).not.toHaveBeenCalled();
  });
});
