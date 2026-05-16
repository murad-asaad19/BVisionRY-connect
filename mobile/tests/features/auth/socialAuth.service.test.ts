jest.mock('~/lib/supabase/client', () => ({
  supabase: { auth: { signInWithOAuth: jest.fn() } },
}));
jest.mock('expo-linking', () => ({
  createURL: jest.fn(() => 'bvisionryconnect://auth/callback'),
}));

import { supabase } from '~/lib/supabase/client';
import { signInWithProvider } from '~/features/auth/services/socialAuth.service';

describe('socialAuth.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('signInWithProvider("apple") calls supabase with apple + redirect', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({ data: {}, error: null });
    await signInWithProvider('apple');
    expect(supabase.auth.signInWithOAuth).toHaveBeenCalledWith({
      provider: 'apple',
      options: { redirectTo: 'bvisionryconnect://auth/callback' },
    });
  });

  it('signInWithProvider("google") calls supabase with google', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({ data: {}, error: null });
    await signInWithProvider('google');
    expect(supabase.auth.signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: { redirectTo: 'bvisionryconnect://auth/callback' },
    });
  });

  it('throws on supabase error', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({
      data: null,
      error: { message: 'oauth failed' },
    });
    await expect(signInWithProvider('google')).rejects.toThrow('oauth failed');
  });
});
