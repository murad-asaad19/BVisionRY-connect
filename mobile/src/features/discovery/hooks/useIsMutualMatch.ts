import { useQuery } from '@tanstack/react-query';
import { isMutualMatch } from '~/features/discovery/services/mutualMatch.service';

/**
 * Returns whether the current user and `otherUserId` are mutual matches.
 *
 * TODO(matching): this hook is intentionally read-only. Side-effects that
 * should fire when a mutual match becomes true (push notification, auto-
 * opened conversation, system message) belong server-side — wire them as
 * a trigger on `public.daily_matches` insert/update rather than reacting
 * to client-side query state, so they fire exactly once and remain
 * consistent across devices.
 */
export function useIsMutualMatch(otherUserId: string | undefined) {
  return useQuery({
    queryKey: ['mutual-match', otherUserId],
    queryFn: () => isMutualMatch(otherUserId!),
    enabled: !!otherUserId,
    staleTime: 5 * 60_000,
  });
}
