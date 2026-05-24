import { mapAuthError } from '~/features/auth/services/errorMap';

/**
 * Table-driven coverage of every recognised Supabase auth error string +
 * the transport/network fallback. Both signIn and signUp modes share the
 * same recognised-string buckets — only the unrecognised-fallback differs,
 * so each table row asserts mode where it matters.
 */
describe('mapAuthError', () => {
  type Case = {
    label: string;
    err: unknown;
    mode: 'signIn' | 'signUp';
    expected: string;
  };

  const cases: ReadonlyArray<Case> = [
    // ── Recognised Supabase auth strings (case-insensitive match) ───────
    {
      label: 'invalid login credentials → invalidCredentials',
      err: new Error('Invalid login credentials'),
      mode: 'signIn',
      expected: 'auth.errors.invalidCredentials',
    },
    {
      label: 'email not confirmed → emailNotConfirmed',
      err: new Error('Email not confirmed'),
      mode: 'signIn',
      expected: 'auth.errors.emailNotConfirmed',
    },
    {
      label: '"rate limit" phrase → rateLimited',
      err: new Error('Email rate limit exceeded'),
      mode: 'signIn',
      expected: 'auth.errors.rateLimited',
    },
    {
      label: 'over_email_send_rate_limit code → rateLimited',
      err: new Error('over_email_send_rate_limit'),
      mode: 'signUp',
      expected: 'auth.errors.rateLimited',
    },
    {
      label: 'over_request_rate_limit code → rateLimited',
      err: new Error('over_request_rate_limit'),
      mode: 'signIn',
      expected: 'auth.errors.rateLimited',
    },
    {
      label: 'too many requests → rateLimited',
      err: new Error('Too many requests'),
      mode: 'signIn',
      expected: 'auth.errors.rateLimited',
    },

    // ── Network / transport detection ───────────────────────────────────
    {
      label: 'AbortError → network',
      err: Object.assign(new Error('aborted'), { name: 'AbortError' }),
      mode: 'signIn',
      expected: 'auth.errors.network',
    },
    {
      label: 'TypeError (fetch failed) → network',
      err: new TypeError('Failed to fetch'),
      mode: 'signIn',
      expected: 'auth.errors.network',
    },
    {
      label: 'FunctionsFetchError → network',
      err: Object.assign(new Error('boom'), { name: 'FunctionsFetchError' }),
      mode: 'signIn',
      expected: 'auth.errors.network',
    },
    {
      label: '"network request failed" message → network',
      err: new Error('Network request failed'),
      mode: 'signIn',
      expected: 'auth.errors.network',
    },

    // ── Mode-specific fallbacks for unrecognised errors ────────────────
    {
      label: 'unknown error, signIn mode → signInFailed',
      err: new Error('Unexpected thing happened'),
      mode: 'signIn',
      expected: 'auth.errors.signInFailed',
    },
    {
      label: 'unknown error, signUp mode → signUpFailed',
      err: new Error('Unexpected thing happened'),
      mode: 'signUp',
      expected: 'auth.errors.signUpFailed',
    },

    // ── Defensive: non-Error inputs ────────────────────────────────────
    {
      label: 'plain object with .message → matched',
      err: { message: 'Invalid login credentials' },
      mode: 'signIn',
      expected: 'auth.errors.invalidCredentials',
    },
    {
      label: 'string input → mode fallback',
      err: 'something else',
      mode: 'signIn',
      expected: 'auth.errors.signInFailed',
    },
    {
      label: 'null → mode fallback',
      err: null,
      mode: 'signUp',
      expected: 'auth.errors.signUpFailed',
    },
  ];

  it.each(cases)('$label', ({ err, mode, expected }) => {
    expect(mapAuthError(err, mode)).toBe(expected);
  });
});
