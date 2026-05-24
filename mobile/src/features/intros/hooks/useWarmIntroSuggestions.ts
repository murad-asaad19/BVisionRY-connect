import { useQuery } from '@tanstack/react-query';
import {
  suggestWarmIntros,
  type WarmIntroSuggestion,
} from '~/features/intros/services/warmIntros.service';
import { useAuthSession } from '~/features/auth/SessionContext';

/**
 * Warm-intro suggestions for the current viewer. Backed by the
 * `suggest_warm_intros` RPC (security definer, authenticated only),
 * so the query is disabled when there's no session — calling the RPC
 * anonymously would raise `unauthenticated`.
 *
 * 10-minute staleTime: mutual graphs change slowly relative to the
 * cost of recomputing them, and the strip is a passive surface (not
 * the primary action), so a refresh on every navigation would burn
 * bandwidth for negligible UX gain.
 */
export function useWarmIntroSuggestions(limit = 10) {
  const { session } = useAuthSession();
  return useQuery<WarmIntroSuggestion[]>({
    queryKey: ['warmIntroSuggestions', session?.user.id, limit],
    queryFn: () => suggestWarmIntros(limit),
    enabled: Boolean(session),
    staleTime: 10 * 60 * 1000,
  });
}
