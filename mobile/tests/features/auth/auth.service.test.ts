jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    auth: {
      signInWithOtp: jest.fn(),
      setSession: jest.fn(),
      exchangeCodeForSession: jest.fn(),
      signOut: jest.fn(),
    },
    rpc: jest.fn(),
  },
}));

jest.mock('~/features/auth/services/redirect', () => ({
  authRedirectUri: 'connect-mobile://auth',
}));

jest.mock('expo-linking', () => ({
  parse: jest.fn(() => ({ queryParams: {} })),
}));

jest.mock('~/lib/query-client', () => ({
  queryClient: { clear: jest.fn() },
}));

jest.mock('~/features/push/services/lastTokenStorage', () => ({
  getLast: jest.fn(),
  clear: jest.fn(),
}));

jest.mock('~/features/discovery/store/feedFiltersStore', () => ({
  useFeedFiltersStore: { getState: () => ({ clear: jest.fn() }) },
}));
jest.mock('~/features/settings/store/telemetryStore', () => ({
  useTelemetryStore: { setState: jest.fn() },
}));
jest.mock('~/features/profile/store/profileNudgeStore', () => ({
  useProfileNudgeStore: { getState: () => ({ reset: jest.fn() }) },
}));
jest.mock('~/features/onboarding/store/useOnboardingDraft', () => ({
  useOnboardingDraft: { getState: () => ({ reset: jest.fn() }) },
}));

import * as Linking from 'expo-linking';
import { supabase } from '~/lib/supabase/client';
import { queryClient } from '~/lib/query-client';
import { getLast } from '~/features/push/services/lastTokenStorage';
import {
  sendMagicLink,
  createSessionFromUrl,
  signOut,
} from '~/features/auth/services/auth.service';

describe('auth.service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (Linking.parse as jest.Mock).mockReturnValue({ queryParams: {} });
  });

  describe('sendMagicLink', () => {
    it('calls signInWithOtp with emailRedirectTo', async () => {
      (supabase.auth.signInWithOtp as jest.Mock).mockResolvedValueOnce({ data: {}, error: null });
      await sendMagicLink('user@example.com');
      expect(supabase.auth.signInWithOtp).toHaveBeenCalledWith({
        email: 'user@example.com',
        options: { emailRedirectTo: 'connect-mobile://auth' },
      });
    });

    it('throws if Supabase returns an error', async () => {
      (supabase.auth.signInWithOtp as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'rate limited' },
      });
      await expect(sendMagicLink('user@example.com')).rejects.toThrow('rate limited');
    });
  });

  describe('createSessionFromUrl', () => {
    it('returns null if URL has no code and no hash tokens', async () => {
      const result = await createSessionFromUrl('connect-mobile://auth');
      expect(result).toBeNull();
      expect(supabase.auth.setSession).not.toHaveBeenCalled();
      expect(supabase.auth.exchangeCodeForSession).not.toHaveBeenCalled();
    });

    it('exchanges the PKCE ?code= for a session', async () => {
      (Linking.parse as jest.Mock).mockReturnValueOnce({ queryParams: { code: 'pkce-code' } });
      (supabase.auth.exchangeCodeForSession as jest.Mock).mockResolvedValueOnce({
        data: { session: { user: { id: 'u-pkce' } } },
        error: null,
      });
      const result = await createSessionFromUrl('connect-mobile://auth?code=pkce-code');
      expect(supabase.auth.exchangeCodeForSession).toHaveBeenCalledWith('pkce-code');
      expect(result?.user.id).toBe('u-pkce');
    });

    it('falls back to implicit hash tokens (legacy magic-link)', async () => {
      (supabase.auth.setSession as jest.Mock).mockResolvedValueOnce({
        data: { session: { user: { id: 'u1' } } },
        error: null,
      });
      const result = await createSessionFromUrl(
        'connect-mobile://auth#access_token=AT&refresh_token=RT&token_type=bearer'
      );
      expect(supabase.auth.setSession).toHaveBeenCalledWith({
        access_token: 'AT',
        refresh_token: 'RT',
      });
      expect(result?.user.id).toBe('u1');
    });

    it('throws if Supabase rejects the session', async () => {
      (supabase.auth.setSession as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'invalid token' },
      });
      await expect(
        createSessionFromUrl('connect-mobile://auth#access_token=AT&refresh_token=RT')
      ).rejects.toThrow('invalid token');
    });
  });

  describe('signOut', () => {
    it('deregisters push, signs out, clears the query cache and resets stores', async () => {
      (getLast as jest.Mock).mockResolvedValueOnce('fcm-token-123');
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      (supabase.auth.signOut as jest.Mock).mockResolvedValueOnce({ error: null });

      await signOut();

      expect(supabase.rpc).toHaveBeenCalledWith('unregister_device_token', {
        p_token: 'fcm-token-123',
      });
      expect(supabase.auth.signOut).toHaveBeenCalled();
      expect(queryClient.clear).toHaveBeenCalled();
    });

    it('does not call the RPC when no FCM token is available', async () => {
      (getLast as jest.Mock).mockResolvedValueOnce(null);
      (supabase.auth.signOut as jest.Mock).mockResolvedValueOnce({ error: null });

      await signOut();

      expect(supabase.rpc).not.toHaveBeenCalled();
      expect(supabase.auth.signOut).toHaveBeenCalled();
    });

    it('still signs out when push deregistration throws', async () => {
      (getLast as jest.Mock).mockRejectedValueOnce(new Error('storage down'));
      (supabase.auth.signOut as jest.Mock).mockResolvedValueOnce({ error: null });

      await expect(signOut()).resolves.toBeUndefined();
      expect(supabase.auth.signOut).toHaveBeenCalled();
    });

    it('throws when supabase.auth.signOut returns an error', async () => {
      (getLast as jest.Mock).mockResolvedValueOnce(null);
      (supabase.auth.signOut as jest.Mock).mockResolvedValueOnce({
        error: { message: 'cannot sign out' },
      });

      await expect(signOut()).rejects.toThrow('cannot sign out');
    });
  });
});
