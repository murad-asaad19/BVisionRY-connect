/**
 * Maps an arbitrary error thrown from Supabase Auth / the handle-login edge
 * function / fetch transport into a stable i18n KEY. Callers pass the result
 * to `t()` for display so localization is uniform across email + handle paths.
 *
 * The shape mirrors the Supabase error.message strings emitted by `gotrue-js`
 * — see https://github.com/supabase/auth-js/blob/main/src/lib/errors.ts.
 * Network/transport errors (offline, AbortError, TypeError from fetch) are
 * detected by name/instance rather than message to avoid English-only checks.
 *
 * `mode` picks the right fallback bucket so an unknown sign-up failure shows
 * "Sign-up failed" instead of "Sign-in failed".
 */
export type AuthMode = 'signIn' | 'signUp';

export function mapAuthError(err: unknown, mode: AuthMode): string {
  // 1) Network / transport — no response from the server.
  if (isNetworkError(err)) return 'auth.errors.network';

  const message = extractMessage(err).toLowerCase();

  // 2) Known Supabase Auth strings.
  if (message.includes('invalid login credentials')) {
    return 'auth.errors.invalidCredentials';
  }
  if (message.includes('email not confirmed')) {
    return 'auth.errors.emailNotConfirmed';
  }
  if (
    message.includes('rate limit') ||
    message.includes('too many requests') ||
    message.includes('over_email_send_rate_limit') ||
    message.includes('over_request_rate_limit')
  ) {
    return 'auth.errors.rateLimited';
  }

  // 3) Mode-specific fallback.
  return mode === 'signUp' ? 'auth.errors.signUpFailed' : 'auth.errors.signInFailed';
}

function extractMessage(err: unknown): string {
  if (err instanceof Error) return err.message;
  if (typeof err === 'string') return err;
  if (err && typeof err === 'object' && 'message' in err) {
    const m = (err as { message: unknown }).message;
    if (typeof m === 'string') return m;
  }
  return '';
}

function isNetworkError(err: unknown): boolean {
  if (!err) return false;
  // AbortError, TypeError (fetch failed), or any error whose name flags it as
  // a transport failure. Supabase's FunctionsFetchError also surfaces here.
  const name = err instanceof Error ? err.name : '';
  if (name === 'AbortError' || name === 'TypeError' || name === 'FunctionsFetchError') {
    return true;
  }
  const msg = extractMessage(err).toLowerCase();
  return (
    msg.includes('failed to fetch') ||
    msg.includes('network request failed') ||
    msg.includes('networkerror')
  );
}
