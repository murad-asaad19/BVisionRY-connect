/**
 * Coverage for the password / handle sign-in surface added in the
 * `feat/password-auth` branch:
 *   - `signUpWithPassword` → wraps `supabase.auth.signUp` with the auth
 *     redirect URI options block.
 *   - `signInWithEmailPassword` → wraps `supabase.auth.signInWithPassword`.
 *   - `signInWithIdentifier` (email path) → routes directly to the email
 *     password flow.
 *   - `signInWithIdentifier` (@handle path) → invokes the
 *     `auth-handle-login` edge function and installs the returned session
 *     via `supabase.auth.setSession`.
 *   - Edge-function failure → throws the canonical "Invalid login
 *     credentials" string so `mapAuthError` collapses both paths onto the
 *     same i18n key.
 *
 * `supabase` is fully mocked at module level so the tests never touch the
 * real SDK. The other side-effects exercised by signOut/etc are mocked off
 * to keep the suite focused.
 */

jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    auth: {
      signUp: jest.fn(),
      signInWithPassword: jest.fn(),
      setSession: jest.fn(),
    },
    functions: { invoke: jest.fn() },
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

jest.mock('~/lib/firebase', () => ({
  getFcmToken: jest.fn(),
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

import { supabase } from '~/lib/supabase/client';
import {
  signUpWithPassword,
  signInWithEmailPassword,
  signInWithIdentifier,
} from '~/features/auth/services/auth.service';

describe('auth.service — password / handle paths', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('signUpWithPassword', () => {
    it('calls supabase.auth.signUp with email, password, and the auth redirect URI', async () => {
      (supabase.auth.signUp as jest.Mock).mockResolvedValueOnce({ data: {}, error: null });
      await signUpWithPassword('new@example.com', 'TestPass123!');
      expect(supabase.auth.signUp).toHaveBeenCalledWith({
        email: 'new@example.com',
        password: 'TestPass123!',
        options: { emailRedirectTo: 'connect-mobile://auth' },
      });
    });

    it('throws when supabase returns an error', async () => {
      (supabase.auth.signUp as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'User already registered' },
      });
      await expect(signUpWithPassword('dup@example.com', 'TestPass123!')).rejects.toThrow(
        'User already registered'
      );
    });
  });

  describe('signInWithEmailPassword', () => {
    it('calls supabase.auth.signInWithPassword with the credentials', async () => {
      (supabase.auth.signInWithPassword as jest.Mock).mockResolvedValueOnce({
        data: {},
        error: null,
      });
      await signInWithEmailPassword('user@example.com', 'TestPass123!');
      expect(supabase.auth.signInWithPassword).toHaveBeenCalledWith({
        email: 'user@example.com',
        password: 'TestPass123!',
      });
    });

    it('throws when supabase returns an error', async () => {
      (supabase.auth.signInWithPassword as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'Invalid login credentials' },
      });
      await expect(signInWithEmailPassword('user@example.com', 'wrong')).rejects.toThrow(
        'Invalid login credentials'
      );
    });
  });

  describe('signInWithIdentifier — email path', () => {
    it('routes plain email through signInWithPassword without touching the edge function', async () => {
      (supabase.auth.signInWithPassword as jest.Mock).mockResolvedValueOnce({
        data: {},
        error: null,
      });
      await signInWithIdentifier('user@example.com', 'TestPass123!');
      expect(supabase.auth.signInWithPassword).toHaveBeenCalledWith({
        email: 'user@example.com',
        password: 'TestPass123!',
      });
      expect(supabase.functions.invoke).not.toHaveBeenCalled();
      expect(supabase.auth.setSession).not.toHaveBeenCalled();
    });

    it('rejects an empty identifier without hitting the network', async () => {
      await expect(signInWithIdentifier('   ', 'TestPass123!')).rejects.toThrow(
        'Email or username is required'
      );
      expect(supabase.auth.signInWithPassword).not.toHaveBeenCalled();
      expect(supabase.functions.invoke).not.toHaveBeenCalled();
    });

    it('rejects a missing password without hitting the network', async () => {
      await expect(signInWithIdentifier('user@example.com', '')).rejects.toThrow(
        'Password is required'
      );
      expect(supabase.auth.signInWithPassword).not.toHaveBeenCalled();
    });
  });

  describe('signInWithIdentifier — @handle path', () => {
    it('invokes auth-handle-login (strips leading @) and installs the returned session', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { access_token: 'AT', refresh_token: 'RT' },
        error: null,
      });
      (supabase.auth.setSession as jest.Mock).mockResolvedValueOnce({
        data: { session: { user: { id: 'u1' } } },
        error: null,
      });
      await signInWithIdentifier('@alice', 'TestPass123!');
      expect(supabase.functions.invoke).toHaveBeenCalledWith('auth-handle-login', {
        body: { handle: 'alice', password: 'TestPass123!' },
      });
      expect(supabase.auth.setSession).toHaveBeenCalledWith({
        access_token: 'AT',
        refresh_token: 'RT',
      });
      // The email-path SDK call must NOT fire for the handle path.
      expect(supabase.auth.signInWithPassword).not.toHaveBeenCalled();
    });

    it('strips multiple leading @ chars off the handle', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { access_token: 'AT', refresh_token: 'RT' },
        error: null,
      });
      (supabase.auth.setSession as jest.Mock).mockResolvedValueOnce({
        data: { session: { user: { id: 'u1' } } },
        error: null,
      });
      await signInWithIdentifier('@@bob', 'TestPass123!');
      expect(supabase.functions.invoke).toHaveBeenCalledWith('auth-handle-login', {
        body: { handle: 'bob', password: 'TestPass123!' },
      });
    });

    it('throws "Invalid login credentials" when the edge function returns an error', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'handle not found' },
      });
      await expect(signInWithIdentifier('@nobody', 'TestPass123!')).rejects.toThrow(
        'Invalid login credentials'
      );
      expect(supabase.auth.setSession).not.toHaveBeenCalled();
    });

    it('throws "Invalid login credentials" when the edge function returns no tokens', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { access_token: '', refresh_token: '' },
        error: null,
      });
      await expect(signInWithIdentifier('@alice', 'wrong')).rejects.toThrow(
        'Invalid login credentials'
      );
      expect(supabase.auth.setSession).not.toHaveBeenCalled();
    });

    it('throws the underlying setSession error when token install fails', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { access_token: 'AT', refresh_token: 'RT' },
        error: null,
      });
      (supabase.auth.setSession as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'token expired' },
      });
      await expect(signInWithIdentifier('@alice', 'TestPass123!')).rejects.toThrow('token expired');
    });
  });
});
