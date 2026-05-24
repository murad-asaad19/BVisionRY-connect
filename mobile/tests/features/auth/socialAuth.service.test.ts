jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    auth: {
      signInWithOAuth: jest.fn(),
      exchangeCodeForSession: jest.fn(),
    },
  },
}));
jest.mock('~/features/auth/services/redirect', () => ({
  authRedirectUri: 'connect-mobile://auth',
}));
jest.mock('expo-web-browser', () => ({
  openAuthSessionAsync: jest.fn(),
}));
jest.mock('expo-linking', () => ({
  parse: jest.fn(),
}));

import * as WebBrowser from 'expo-web-browser';
import * as Linking from 'expo-linking';
import { supabase } from '~/lib/supabase/client';
import { signInWithProvider } from '~/features/auth/services/socialAuth.service';

describe('socialAuth.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('signInWithProvider drives the PKCE flow end-to-end and resolves to "success"', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({
      data: { url: 'https://provider.example/authorize?...' },
      error: null,
    });
    (WebBrowser.openAuthSessionAsync as jest.Mock).mockResolvedValueOnce({
      type: 'success',
      url: 'connect-mobile://auth?code=abc123',
    });
    (Linking.parse as jest.Mock).mockReturnValueOnce({ queryParams: { code: 'abc123' } });
    (supabase.auth.exchangeCodeForSession as jest.Mock).mockResolvedValueOnce({
      data: { session: {} },
      error: null,
    });

    await expect(signInWithProvider('google')).resolves.toBe('success');

    expect(supabase.auth.signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: { redirectTo: 'connect-mobile://auth', skipBrowserRedirect: true },
    });
    expect(WebBrowser.openAuthSessionAsync).toHaveBeenCalledWith(
      'https://provider.example/authorize?...',
      'connect-mobile://auth',
      { preferEphemeralSession: true }
    );
    expect(supabase.auth.exchangeCodeForSession).toHaveBeenCalledWith('abc123');
  });

  it('passes the apple provider through verbatim', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({
      data: { url: 'https://appleid.apple.com/authorize' },
      error: null,
    });
    (WebBrowser.openAuthSessionAsync as jest.Mock).mockResolvedValueOnce({
      type: 'success',
      url: 'connect-mobile://auth?code=xyz',
    });
    (Linking.parse as jest.Mock).mockReturnValueOnce({ queryParams: { code: 'xyz' } });
    (supabase.auth.exchangeCodeForSession as jest.Mock).mockResolvedValueOnce({
      data: { session: {} },
      error: null,
    });

    await signInWithProvider('apple');

    expect(supabase.auth.signInWithOAuth).toHaveBeenCalledWith({
      provider: 'apple',
      options: { redirectTo: 'connect-mobile://auth', skipBrowserRedirect: true },
    });
  });

  it('returns "cancelled" when the user dismisses the browser sheet', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({
      data: { url: 'https://provider.example/authorize' },
      error: null,
    });
    (WebBrowser.openAuthSessionAsync as jest.Mock).mockResolvedValueOnce({ type: 'cancel' });

    await expect(signInWithProvider('google')).resolves.toBe('cancelled');
    expect(supabase.auth.exchangeCodeForSession).not.toHaveBeenCalled();
  });

  it('throws on supabase init error', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({
      data: null,
      error: { message: 'oauth failed' },
    });

    await expect(signInWithProvider('google')).rejects.toThrow('oauth failed');
  });

  it('throws when exchangeCodeForSession errors', async () => {
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({
      data: { url: 'https://provider.example/authorize' },
      error: null,
    });
    (WebBrowser.openAuthSessionAsync as jest.Mock).mockResolvedValueOnce({
      type: 'success',
      url: 'connect-mobile://auth?code=abc',
    });
    (Linking.parse as jest.Mock).mockReturnValueOnce({ queryParams: { code: 'abc' } });
    (supabase.auth.exchangeCodeForSession as jest.Mock).mockResolvedValueOnce({
      data: null,
      error: { message: 'exchange failed' },
    });

    await expect(signInWithProvider('google')).rejects.toThrow('exchange failed');
  });

  it('throws a normalised Error when the callback URL carries ?error=...&error_description=...', async () => {
    // OAuth providers (Google, Apple) signal user-facing failures by
    // redirecting back to the app's callback URL with `error` and
    // `error_description` query params instead of a `code`. Without this
    // guard, the code-extraction path would throw a misleading "no code"
    // error; surface the provider's own message instead so the UI layer
    // can localise / display it.
    (supabase.auth.signInWithOAuth as jest.Mock).mockResolvedValueOnce({
      data: { url: 'https://provider.example/authorize' },
      error: null,
    });
    (WebBrowser.openAuthSessionAsync as jest.Mock).mockResolvedValueOnce({
      type: 'success',
      url: 'connect-mobile://auth?error=access_denied&error_description=User%20denied%20consent',
    });
    (Linking.parse as jest.Mock).mockReturnValueOnce({
      queryParams: {
        error: 'access_denied',
        error_description: 'User denied consent',
      },
    });

    // The description is preferred over the code; both must be considered
    // failures even if no `code` is present.
    await expect(signInWithProvider('google')).rejects.toThrow('User denied consent');
    expect(supabase.auth.exchangeCodeForSession).not.toHaveBeenCalled();
  });
});
