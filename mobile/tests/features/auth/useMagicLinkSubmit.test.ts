/**
 * Coverage for the shared `useMagicLinkSubmit` hook used by both SignInForm
 * and SignUpForm.
 *
 * Asserts the four state transitions:
 *   1. Invalid email → errorKey = `magicLinkNeedsEmail`, no network call.
 *   2. Happy path → submitting flips false, sentTo = email, no errorKey.
 *   3. Underlying throw → errorKey via `mapAuthError(mode)`.
 *   4. `reset()` clears the banner when one is set.
 */

jest.mock('~/features/auth/services/auth.service', () => ({
  sendMagicLink: jest.fn(),
}));

import { act, renderHook } from '@testing-library/react-native';

import { useMagicLinkSubmit } from '~/features/auth/hooks/useMagicLinkSubmit';
import { sendMagicLink } from '~/features/auth/services/auth.service';

describe('useMagicLinkSubmit', () => {
  beforeEach(() => jest.clearAllMocks());

  it('blocks invalid emails and surfaces magicLinkNeedsEmail without calling the service', async () => {
    const { result } = renderHook(() =>
      useMagicLinkSubmit({ getEmail: () => 'not-an-email', mode: 'signIn' })
    );

    await act(async () => {
      await result.current.send();
    });

    expect(result.current.errorKey).toBe('auth.errors.magicLinkNeedsEmail');
    expect(result.current.sentTo).toBeNull();
    expect(result.current.submitting).toBe(false);
    expect(sendMagicLink).not.toHaveBeenCalled();
  });

  it('sends the link and records sentTo on success', async () => {
    (sendMagicLink as jest.Mock).mockResolvedValueOnce(undefined);

    const { result } = renderHook(() =>
      useMagicLinkSubmit({ getEmail: () => 'user@example.com', mode: 'signIn' })
    );

    await act(async () => {
      await result.current.send();
    });

    expect(sendMagicLink).toHaveBeenCalledWith('user@example.com');
    expect(result.current.errorKey).toBeNull();
    expect(result.current.sentTo).toBe('user@example.com');
    expect(result.current.submitting).toBe(false);
  });

  it('trims surrounding whitespace before validating + sending', async () => {
    (sendMagicLink as jest.Mock).mockResolvedValueOnce(undefined);

    const { result } = renderHook(() =>
      useMagicLinkSubmit({ getEmail: () => '   user@example.com   ', mode: 'signUp' })
    );

    await act(async () => {
      await result.current.send();
    });

    expect(sendMagicLink).toHaveBeenCalledWith('user@example.com');
  });

  it('maps an Invalid login credentials throw to invalidCredentials (signIn mode)', async () => {
    (sendMagicLink as jest.Mock).mockRejectedValueOnce(new Error('Invalid login credentials'));

    const { result } = renderHook(() =>
      useMagicLinkSubmit({ getEmail: () => 'user@example.com', mode: 'signIn' })
    );

    await act(async () => {
      await result.current.send();
    });

    expect(result.current.errorKey).toBe('auth.errors.invalidCredentials');
    expect(result.current.sentTo).toBeNull();
    expect(result.current.submitting).toBe(false);
  });

  it('falls back to the sign-up bucket for unrecognised errors in signUp mode', async () => {
    (sendMagicLink as jest.Mock).mockRejectedValueOnce(new Error('Boom — unknown failure'));

    const { result } = renderHook(() =>
      useMagicLinkSubmit({ getEmail: () => 'user@example.com', mode: 'signUp' })
    );

    await act(async () => {
      await result.current.send();
    });

    expect(result.current.errorKey).toBe('auth.errors.signUpFailed');
  });

  it('reset() clears the errorKey banner once set', async () => {
    (sendMagicLink as jest.Mock).mockRejectedValueOnce(new Error('Invalid login credentials'));

    const { result } = renderHook(() =>
      useMagicLinkSubmit({ getEmail: () => 'user@example.com', mode: 'signIn' })
    );

    await act(async () => {
      await result.current.send();
    });
    expect(result.current.errorKey).toBe('auth.errors.invalidCredentials');

    act(() => {
      result.current.reset();
    });

    expect(result.current.errorKey).toBeNull();
    expect(result.current.sentTo).toBeNull();
  });

  it('reset() clears the sentTo banner once set', async () => {
    (sendMagicLink as jest.Mock).mockResolvedValueOnce(undefined);

    const { result } = renderHook(() =>
      useMagicLinkSubmit({ getEmail: () => 'user@example.com', mode: 'signIn' })
    );

    await act(async () => {
      await result.current.send();
    });
    expect(result.current.sentTo).toBe('user@example.com');

    act(() => {
      result.current.reset();
    });

    expect(result.current.sentTo).toBeNull();
  });
});
