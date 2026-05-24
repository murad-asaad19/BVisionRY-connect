/**
 * Unit-tests the pure `getNextHref(state)` mapping and the `useNextRoute`
 * hook's state-derivation across the five canonical auth-gate branches.
 *
 * The hook itself is exercised by stubbing its two dependencies
 * (`useAuthSession`, `useCurrentUserProfile`) and rendering via
 * `react-test-renderer`'s `act()`-aware harness from React Testing Library.
 */

const mockUseAuthSession = jest.fn();
const mockUseCurrentUserProfile = jest.fn();

jest.mock('~/features/auth/SessionContext', () => ({
  useAuthSession: () => mockUseAuthSession(),
}));

jest.mock('~/features/profile/hooks/useCurrentUserProfile', () => ({
  useCurrentUserProfile: () => mockUseCurrentUserProfile(),
}));

import { renderHook } from '@testing-library/react-native';
import {
  useNextRoute,
  getNextHref,
  type NextRouteState,
} from '~/features/auth/hooks/useNextRoute';

type Profile = { onboarded: boolean; suspended_at: string | null };

type Case = {
  label: string;
  session: { user: { id: string } } | null;
  sessionLoading: boolean;
  profile: Profile | null;
  profileLoading: boolean;
  expected: { state: NextRouteState; href: ReturnType<typeof getNextHref> };
};

const CASES: ReadonlyArray<Case> = [
  {
    label: 'session loading → loading / null',
    session: null,
    sessionLoading: true,
    profile: null,
    profileLoading: false,
    expected: { state: 'loading', href: null },
  },
  {
    label: 'session present but profile loading → loading / null',
    session: { user: { id: 'u1' } },
    sessionLoading: false,
    profile: null,
    profileLoading: true,
    expected: { state: 'loading', href: null },
  },
  {
    label: 'no session → unauthed / sign-in',
    session: null,
    sessionLoading: false,
    profile: null,
    profileLoading: false,
    expected: { state: 'unauthed', href: '/(auth)/sign-in' },
  },
  {
    label: 'session + suspended profile → suspended',
    session: { user: { id: 'u1' } },
    sessionLoading: false,
    profile: { onboarded: true, suspended_at: '2026-01-01T00:00:00Z' },
    profileLoading: false,
    expected: { state: 'suspended', href: '/suspended' },
  },
  {
    label: 'session + not-onboarded profile → onboarding',
    session: { user: { id: 'u1' } },
    sessionLoading: false,
    profile: { onboarded: false, suspended_at: null },
    profileLoading: false,
    expected: { state: 'onboarding', href: '/(onboarding)/goal' },
  },
  {
    label: 'session + onboarded profile → app',
    session: { user: { id: 'u1' } },
    sessionLoading: false,
    profile: { onboarded: true, suspended_at: null },
    profileLoading: false,
    expected: { state: 'app', href: '/(app)/(tabs)/home' },
  },
];

describe('getNextHref (pure)', () => {
  it.each(CASES)('$label', ({ expected }) => {
    expect(getNextHref(expected.state)).toBe(expected.href);
  });
});

describe('useNextRoute (hook)', () => {
  beforeEach(() => {
    mockUseAuthSession.mockReset();
    mockUseCurrentUserProfile.mockReset();
  });

  it.each(CASES)('$label', ({ session, sessionLoading, profile, profileLoading, expected }) => {
    mockUseAuthSession.mockReturnValue({ session, loading: sessionLoading });
    mockUseCurrentUserProfile.mockReturnValue({ data: profile, isLoading: profileLoading });
    const { result } = renderHook(() => useNextRoute());
    expect(result.current).toEqual(expected);
  });
});
