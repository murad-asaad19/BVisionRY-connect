import { useQuery } from '@tanstack/react-query';
import { isMutualMatch } from '~/features/discovery/services/mutualMatch.service';

export function useIsMutualMatch(otherUserId: string | undefined) {
  return useQuery({
    queryKey: ['mutual-match', otherUserId],
    queryFn: () => isMutualMatch(otherUserId!),
    enabled: !!otherUserId,
    staleTime: 5 * 60_000,
  });
}
