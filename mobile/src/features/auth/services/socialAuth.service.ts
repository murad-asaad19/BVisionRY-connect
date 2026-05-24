import * as WebBrowser from 'expo-web-browser';
import * as Linking from 'expo-linking';
import { supabase } from '~/lib/supabase/client';
import { authRedirectUri } from '~/features/auth/services/redirect';

export type SocialProvider = 'apple' | 'google';

export type SocialSignInResult = 'success' | 'cancelled';

/**
 * Drive the OAuth handshake on native via expo-web-browser.
 *
 * `signInWithOAuth` on RN doesn't open a browser — it just returns the
 * provider URL. We open it ourselves through `openAuthSessionAsync` (an
 * ASWebAuthenticationSession / Custom Tab) so the user stays in-app and
 * we get the callback URL back. Then we exchange the `?code=` for a session.
 *
 * Returns `'cancelled'` when the user dismisses the sheet — callers should
 * treat this as a non-error.
 */
export async function signInWithProvider(provider: SocialProvider): Promise<SocialSignInResult> {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: authRedirectUri,
      // We open the browser ourselves below; tell the SDK to stand down.
      skipBrowserRedirect: true,
    },
  });
  if (error) throw new Error(error.message);
  if (!data?.url) throw new Error('OAuth init returned no URL');

  // `preferEphemeralSession: true` opts out of cross-app cookie/credential
  // sharing on iOS (ASWebAuthenticationSession ephemeral mode) and the
  // equivalent on Android. Without it, each OAuth round-trip can prefill
  // the previously-signed-in IdP account, which leaks the prior user's
  // identity to the device and surprises users who expect account isolation.
  const result = await WebBrowser.openAuthSessionAsync(data.url, authRedirectUri, {
    preferEphemeralSession: true,
  });

  // User dismissed the sheet or the browser failed to open — not an error.
  if (result.type !== 'success' || !result.url) return 'cancelled';

  const queryParams = Linking.parse(result.url).queryParams ?? {};

  // OAuth providers signal user-facing failures via `?error=...&error_description=...`
  // on the callback URL. Mirror `auth.service.createSessionFromUrl` and surface
  // these BEFORE the code extraction — otherwise we'd silently throw "OAuth
  // callback returned no code" when the real failure was e.g. the user denying
  // consent or the IdP rejecting the request.
  const errorCode = typeof queryParams.error === 'string' ? queryParams.error : null;
  const errorDescription =
    typeof queryParams.error_description === 'string' ? queryParams.error_description : null;
  if (errorCode || errorDescription) {
    throw new Error(errorDescription ?? errorCode ?? 'OAuth callback error');
  }

  const code = queryParams.code;
  if (typeof code !== 'string' || !code) {
    throw new Error('OAuth callback returned no code');
  }

  const { error: exchangeError } = await supabase.auth.exchangeCodeForSession(code);
  if (exchangeError) throw new Error(exchangeError.message);

  return 'success';
}
