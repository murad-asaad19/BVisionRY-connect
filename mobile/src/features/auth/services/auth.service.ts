import * as Linking from 'expo-linking';
import { supabase } from '~/lib/supabase/client';
import { queryClient } from '~/lib/query-client';
import { getLast, clear as clearLastToken } from '~/features/push/services/lastTokenStorage';
import { useFeedFiltersStore } from '~/features/discovery/store/feedFiltersStore';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';
import { useProfileNudgeStore } from '~/features/profile/store/profileNudgeStore';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { authRedirectUri } from '~/features/auth/services/redirect';

export { authRedirectUri };

export async function sendMagicLink(email: string): Promise<void> {
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: authRedirectUri },
  });
  if (error) throw new Error(error.message);
}

export async function signUpWithPassword(email: string, password: string): Promise<void> {
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: { emailRedirectTo: authRedirectUri },
  });
  if (error) throw new Error(error.message);
}

export async function signInWithEmailPassword(email: string, password: string): Promise<void> {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);
}

/**
 * Sign in with either an email address or a public handle ("@username").
 *
 * Email path: `signInWithPassword({email, password})` directly.
 *
 * Handle path: the handle → email mapping is no longer exposed to anon
 * clients (revoked in 20260606060000_revoke_handle_lookup.sql). We POST
 * to the `auth-handle-login` edge function, which holds the service-role
 * key, validates the handle, looks up the email, and runs the password
 * check server-side. On success it returns a session payload we install
 * locally via `setSession`. On failure it returns a generic 401 — we
 * surface the same error string Supabase Auth uses for bad credentials
 * so the form's existing error-mapping treats both paths identically.
 */
export async function signInWithIdentifier(identifier: string, password: string): Promise<void> {
  const trimmed = identifier.trim();
  if (!trimmed) throw new Error('Email or username is required');
  if (!password) throw new Error('Password is required');

  // Email-path: contains "@" anywhere other than as the first character.
  // (Bare "@" prefix is the handle convention — strip it for the handle path.)
  const looksLikeEmail = trimmed.includes('@') && !trimmed.startsWith('@');
  if (looksLikeEmail) {
    await signInWithEmailPassword(trimmed, password);
    return;
  }

  const handle = trimmed.replace(/^@+/, '');

  const { data, error } = await supabase.functions.invoke<{
    access_token: string;
    refresh_token: string;
  }>('auth-handle-login', {
    body: { handle, password },
  });

  // supabase-js surfaces non-2xx as FunctionsHttpError on `error`, NOT on
  // `data`. Either branch is a sign-in failure — throw the same string
  // Supabase Auth uses for bad credentials so the form maps both paths to
  // the same i18n key (auth.errors.invalidCredentials).
  if (error || !data?.access_token || !data?.refresh_token) {
    throw new Error('Invalid login credentials');
  }

  const { error: setErr } = await supabase.auth.setSession({
    access_token: data.access_token,
    refresh_token: data.refresh_token,
  });
  if (setErr) throw new Error(setErr.message);
}

function parseHashParams(url: string): Record<string, string> {
  const hashIndex = url.indexOf('#');
  if (hashIndex === -1) return {};
  const fragment = url.slice(hashIndex + 1);
  return Object.fromEntries(
    fragment.split('&').map((pair) => {
      const [k, v] = pair.split('=');
      return [decodeURIComponent(k ?? ''), decodeURIComponent(v ?? '')];
    })
  );
}

/**
 * Resolve a deep-link callback URL into a Supabase session.
 *
 * Handles both flows:
 *  - Implicit (legacy): `#access_token=...&refresh_token=...` → `setSession`.
 *  - PKCE (default since flowType:'pkce'): `?code=...` → `exchangeCodeForSession`.
 *
 * Returns the resolved session or null when the URL carries no auth payload.
 */
export async function createSessionFromUrl(url: string) {
  const queryParams = Linking.parse(url).queryParams ?? {};

  // OAuth/magic-link error callbacks arrive as `?error=...&error_description=...`.
  // Surface these immediately — otherwise the function silently returns null
  // and callers think "no session payload" rather than "the IdP rejected the
  // user". Check BEFORE the code branch: error callbacks have no `code` and
  // would otherwise fall through to the hash check and resolve to null.
  const errorCode = typeof queryParams.error === 'string' ? queryParams.error : null;
  const errorDescription =
    typeof queryParams.error_description === 'string' ? queryParams.error_description : null;
  if (errorCode || errorDescription) {
    throw new Error(errorDescription ?? errorCode ?? 'OAuth callback error');
  }

  // PKCE first — the SDK default now emits `?code=` for both OAuth and
  // magic-link callbacks.
  const code = typeof queryParams.code === 'string' ? queryParams.code : null;
  if (code) {
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    if (error) throw new Error(error.message);
    return data.session;
  }

  // Implicit-flow fallback (e.g. older magic-link templates still using #).
  const params = parseHashParams(url);
  const access_token = params.access_token;
  const refresh_token = params.refresh_token;
  if (!access_token || !refresh_token) return null;
  const { data, error } = await supabase.auth.setSession({ access_token, refresh_token });
  if (error) throw new Error(error.message);
  return data.session;
}

/**
 * Best-effort device-token deregistration. Calls the `unregister_device_token`
 * RPC (added in 20260606000000_rls_hardening.sql). Failure is swallowed —
 * push-cleanup must never block the user from signing out.
 *
 * Reads the last-registered token from AsyncStorage rather than calling
 * `getFcmToken()`. Going through Firebase would trigger
 * `messaging().requestPermission()` and a network round-trip — both
 * undesirable side effects during sign-out, and `requestPermission` may
 * surface an OS prompt if the user has revoked notifications since the
 * original register. The AsyncStorage entry is maintained by
 * `useRegisterFcmToken` on register / token-refresh.
 */
async function deregisterPushToken(): Promise<void> {
  try {
    const token = await getLast();
    if (!token) return;
    await supabase.rpc('unregister_device_token', { p_token: token });
    // Even if the RPC throws, clear the local entry so a stale token doesn't
    // linger across the next user's session on this device.
  } catch (e) {
    console.warn('[auth] deregisterPushToken failed', e);
  } finally {
    await clearLastToken();
  }
}

/**
 * Sign the current user out and scrub any per-account client state so the
 * next user gets a clean app: react-query cache, persisted Zustand stores,
 * and the server-side FCM device-token record.
 */
export async function signOut(): Promise<void> {
  // Deregister push BEFORE sign-out — the RPC requires an authenticated user.
  await deregisterPushToken();

  // `scope: 'local'` only invalidates the current device's session. The
  // default `'global'` would revoke refresh tokens on every device the user
  // is signed in on — a hostile UX for users who sign out on one phone.
  const { error } = await supabase.auth.signOut({ scope: 'local' });
  if (error) throw new Error(error.message);

  // Clear all cached server data.
  queryClient.clear();

  // Reset persisted Zustand stores so the next sign-in starts from defaults.
  // (feedFiltersStore uses `clear()`; the others expose `reset()`.)
  try {
    useFeedFiltersStore.getState().clear();
    useProfileNudgeStore.getState().reset();
    useOnboardingDraft.getState().reset();
    // GDPR opt-out: telemetry resets to disabled so the next user on this
    // device must explicitly opt back in via Settings. Persisting the
    // previous user's preference would be a data-protection violation.
    useTelemetryStore.setState({ analyticsEnabled: false, crashReportsEnabled: false });
  } catch (e) {
    console.warn('[auth] store reset failed', e);
  }
}
