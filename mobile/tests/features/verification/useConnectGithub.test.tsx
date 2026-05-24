/**
 * Coverage for the GitHub identity-link orchestrator hook
 * `useConnectGithub`.
 *
 * The hook can't gate on `useMutation.isPending` because `linkIdentity`
 * resolves the moment the in-app browser opens — long before the user has
 * actually authorized on GitHub. It instead flips its own `awaiting` flag,
 * subscribes to `supabase.auth.onAuthStateChange`, and finalises on the
 * `USER_UPDATED` event.
 *
 * These tests drive the hook through that sequence:
 *   1. mutate() flips `awaiting` and subscribes to onAuthStateChange.
 *   2. Firing USER_UPDATED with a github identity attached triggers
 *      `setGithubVerification` and the `['profile']` query invalidation.
 *   3. Failure to persist surfaces as an Alert (and `awaiting` still clears).
 *   4. A USER_UPDATED without a github identity is ignored.
 *
 * The QueryClient is real (so we can assert invalidateQueries fired); every
 * other side-effect (supabase, services, Alert) is mocked.
 */

import React from 'react';
import { Alert } from 'react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { act, renderHook, waitFor } from '@testing-library/react-native';

jest.mock('expo-linking', () => ({
  createURL: jest.fn(() => 'connect-mobile://auth/callback'),
}));

const mockOnAuthStateChange = jest.fn();
const mockGetUser = jest.fn();
jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    auth: {
      onAuthStateChange: (...args: unknown[]) => mockOnAuthStateChange(...args),
      getUser: (...args: unknown[]) => mockGetUser(...args),
    },
  },
}));

const mockBeginGithubOAuth = jest.fn();
const mockExtractGithubIdentity = jest.fn();
const mockSetGithubVerification = jest.fn();
jest.mock('~/features/verification/services/verification.service', () => ({
  beginGithubOAuth: (...args: unknown[]) => mockBeginGithubOAuth(...args),
  extractGithubIdentity: (...args: unknown[]) => mockExtractGithubIdentity(...args),
  setGithubVerification: (...args: unknown[]) => mockSetGithubVerification(...args),
}));

jest.mock('i18next', () => ({
  t: (k: string) => k,
}));

import { useConnectGithub } from '~/features/verification/hooks/useConnectGithub';

type AuthCallback = (event: string) => void | Promise<void>;

function wrapWithClient(qc: QueryClient) {
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
  };
}

describe('useConnectGithub', () => {
  let qc: QueryClient;
  let alertSpy: jest.SpyInstance;
  let lastCallback: AuthCallback | null;
  let unsubscribe: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    lastCallback = null;
    unsubscribe = jest.fn();
    mockOnAuthStateChange.mockImplementation((cb: AuthCallback) => {
      lastCallback = cb;
      return { data: { subscription: { unsubscribe } } };
    });
    qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    alertSpy = jest.spyOn(Alert, 'alert').mockImplementation(() => {});
  });

  afterEach(() => {
    qc.clear();
    alertSpy.mockRestore();
  });

  it('finalises the link on USER_UPDATED with a github identity', async () => {
    mockBeginGithubOAuth.mockResolvedValueOnce(undefined);
    mockGetUser.mockResolvedValueOnce({
      data: { user: { id: 'u1', identities: [{ provider: 'github' }] } },
      error: null,
    });
    mockExtractGithubIdentity.mockReturnValueOnce({ username: 'octocat', id: 12345 });
    mockSetGithubVerification.mockResolvedValueOnce(undefined);
    const invalidateSpy = jest.spyOn(qc, 'invalidateQueries');

    const { result } = renderHook(() => useConnectGithub(), { wrapper: wrapWithClient(qc) });

    await act(async () => {
      await result.current.mutateAsync();
    });

    // The mutation resolves the moment the OAuth browser opens. The
    // onAuthStateChange listener is wired during the post-mutation render.
    await waitFor(() => expect(mockOnAuthStateChange).toHaveBeenCalled());
    expect(lastCallback).not.toBeNull();

    await act(async () => {
      await lastCallback?.('USER_UPDATED');
    });

    expect(mockSetGithubVerification).toHaveBeenCalledWith('octocat', 12345);
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['profile'] });
    expect(alertSpy).not.toHaveBeenCalled();
  });

  it('ignores USER_UPDATED events that carry no github identity', async () => {
    mockBeginGithubOAuth.mockResolvedValueOnce(undefined);
    mockGetUser.mockResolvedValueOnce({
      data: { user: { id: 'u1', identities: [{ provider: 'email' }] } },
      error: null,
    });
    mockExtractGithubIdentity.mockReturnValueOnce(null);

    const { result } = renderHook(() => useConnectGithub(), { wrapper: wrapWithClient(qc) });
    await act(async () => {
      await result.current.mutateAsync();
    });

    await waitFor(() => expect(mockOnAuthStateChange).toHaveBeenCalled());

    await act(async () => {
      await lastCallback?.('USER_UPDATED');
    });

    expect(mockSetGithubVerification).not.toHaveBeenCalled();
    expect(alertSpy).not.toHaveBeenCalled();
  });

  it('surfaces a setGithubVerification failure via Alert and still cleans up', async () => {
    mockBeginGithubOAuth.mockResolvedValueOnce(undefined);
    mockGetUser.mockResolvedValueOnce({
      data: { user: { id: 'u1', identities: [{ provider: 'github' }] } },
      error: null,
    });
    mockExtractGithubIdentity.mockReturnValueOnce({ username: 'octocat', id: 12345 });
    mockSetGithubVerification.mockRejectedValueOnce(new Error('rpc denied'));

    const { result } = renderHook(() => useConnectGithub(), { wrapper: wrapWithClient(qc) });
    await act(async () => {
      await result.current.mutateAsync();
    });

    await waitFor(() => expect(mockOnAuthStateChange).toHaveBeenCalled());

    await act(async () => {
      await lastCallback?.('USER_UPDATED');
    });

    expect(alertSpy).toHaveBeenCalledWith('verification.connectFailed.title', 'rpc denied');
  });

  it('does not finalise on non USER_UPDATED events', async () => {
    mockBeginGithubOAuth.mockResolvedValueOnce(undefined);

    const { result } = renderHook(() => useConnectGithub(), { wrapper: wrapWithClient(qc) });
    await act(async () => {
      await result.current.mutateAsync();
    });

    await waitFor(() => expect(mockOnAuthStateChange).toHaveBeenCalled());

    await act(async () => {
      await lastCallback?.('SIGNED_IN');
    });

    expect(mockGetUser).not.toHaveBeenCalled();
    expect(mockSetGithubVerification).not.toHaveBeenCalled();
  });
});
