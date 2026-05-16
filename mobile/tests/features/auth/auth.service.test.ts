jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    auth: {
      signInWithOtp: jest.fn(),
      setSession: jest.fn(),
      signOut: jest.fn(),
    },
  },
}));

jest.mock('expo-auth-session', () => ({
  makeRedirectUri: jest.fn(() => 'connect-mobile://auth'),
}));

import { supabase } from '~/lib/supabase/client';
import {
  sendMagicLink,
  createSessionFromUrl,
  signOut,
} from '~/features/auth/services/auth.service';

describe('auth.service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
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
    it('returns null if URL has no access_token', async () => {
      const result = await createSessionFromUrl('connect-mobile://auth');
      expect(result).toBeNull();
      expect(supabase.auth.setSession).not.toHaveBeenCalled();
    });

    it('calls setSession with parsed tokens', async () => {
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
    it('calls supabase.auth.signOut', async () => {
      (supabase.auth.signOut as jest.Mock).mockResolvedValueOnce({ error: null });
      await signOut();
      expect(supabase.auth.signOut).toHaveBeenCalled();
    });
  });
});
