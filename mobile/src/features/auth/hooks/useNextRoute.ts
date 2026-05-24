import type { Href } from 'expo-router';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import type { Database } from '~/lib/supabase/types.gen';

type Profile = Database['public']['Tables']['profiles']['Row'];

export type NextRouteState = 'loading' | 'unauthed' | 'suspended' | 'onboarding' | 'app';

export type NextRoute = {
  state: NextRouteState;
  href: Href | null;
};

/**
 * Pure mapping from a derived auth-gate `state` to the canonical destination
 * route. Kept as a stand-alone export so tests can exercise the routing table
 * without a React tree.
 *
 * The `profile` argument is unused (state already encodes the decision) but
 * the signature is preserved so future branches can refine the destination
 * (e.g. picking an onboarding sub-step based on draft progress).
 */
export function getNextHref(state: NextRouteState, _profile?: Profile | null): Href | null {
  switch (state) {
    case 'loading':
      return null;
    case 'unauthed':
      return '/(auth)/sign-in';
    case 'suspended':
      return '/suspended';
    case 'onboarding':
      return '/(onboarding)/goal';
    case 'app':
      return '/(app)/(tabs)/home';
  }
}

/**
 * Single source of truth for the auth gate. Each layout that participates in
 * the gate (root index, `(app)/_layout`, `(auth)/_layout`) calls this hook
 * and renders either a loading spinner, a redirect to `href`, or its own
 * children — based on whether the returned `state` matches that layout's
 * "happy path" group.
 */
export function useNextRoute(): NextRoute {
  const { session, loading: sessionLoading } = useAuthSession();
  const { data: profile, isLoading: profileLoading } = useCurrentUserProfile();

  if (sessionLoading || (session && profileLoading)) {
    return { state: 'loading', href: null };
  }

  if (!session) {
    return { state: 'unauthed', href: getNextHref('unauthed') };
  }

  if (profile?.suspended_at) {
    return { state: 'suspended', href: getNextHref('suspended') };
  }

  if (!profile?.onboarded) {
    return { state: 'onboarding', href: getNextHref('onboarding') };
  }

  return { state: 'app', href: getNextHref('app') };
}
