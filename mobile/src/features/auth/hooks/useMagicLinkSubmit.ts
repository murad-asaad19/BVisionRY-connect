import { useCallback, useState } from 'react';
import { z } from 'zod';
import { sendMagicLink } from '~/features/auth/services/auth.service';
import { mapAuthError, type AuthMode } from '~/features/auth/services/errorMap';

const EmailSchema = z.string().email();

type Options = {
  /** Pulled lazily so we always read the latest form value at click time. */
  getEmail: () => string;
  /**
   * Error namespace fallback. SignUp -> `auth.errors.signUpFailed`,
   * SignIn -> `auth.errors.signInFailed`.
   */
  mode: AuthMode;
};

type State = {
  submitting: boolean;
  /** i18n key for the localized error, or null. */
  errorKey: string | null;
  /** Email the link was sent to (drives the success caption). */
  sentTo: string | null;
};

/**
 * Shared "send me a magic link" submit handler used by both SignInForm and
 * SignUpForm. Centralizes:
 *   - email validation (must be a full email, not an @handle)
 *   - submitting flag for the spinner
 *   - error mapping via {@link mapAuthError}
 *   - success state (the email we sent to)
 */
export function useMagicLinkSubmit({ getEmail, mode }: Options) {
  const [state, setState] = useState<State>({
    submitting: false,
    errorKey: null,
    sentTo: null,
  });

  const send = useCallback(async () => {
    const email = getEmail().trim();
    if (!EmailSchema.safeParse(email).success) {
      setState({ submitting: false, errorKey: 'auth.errors.magicLinkNeedsEmail', sentTo: null });
      return;
    }

    setState({ submitting: true, errorKey: null, sentTo: null });
    try {
      await sendMagicLink(email);
      setState({ submitting: false, errorKey: null, sentTo: email });
    } catch (e) {
      setState({ submitting: false, errorKey: mapAuthError(e, mode), sentTo: null });
    }
  }, [getEmail, mode]);

  /** Clears the error/sentTo banner — call when the user edits the email. */
  const reset = useCallback(() => {
    setState((s) => (s.errorKey || s.sentTo ? { ...s, errorKey: null, sentTo: null } : s));
  }, []);

  return {
    submitting: state.submitting,
    errorKey: state.errorKey,
    sentTo: state.sentTo,
    send,
    reset,
  };
}
