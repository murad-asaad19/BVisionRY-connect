import { useQuery } from '@tanstack/react-query';
import {
  listOpportunities,
  type ListOpportunitiesFilters,
  type OpportunityFeedItem,
} from '~/features/opportunities/services/opportunities.service';
import { useAuthSession } from '~/features/auth/SessionContext';

/**
 * Feed query for the Opportunities board. Disabled when there's no
 * session — the backing RPC requires an authenticated caller.
 *
 * `filters` is part of the query key so toggling kinds / remote / the
 * search input swaps the cache entry rather than refetching the same key.
 */
export function useOpportunities(filters: ListOpportunitiesFilters = {}) {
  const { session } = useAuthSession();
  return useQuery<OpportunityFeedItem[]>({
    queryKey: ['opportunities', 'feed', session?.user.id, filters],
    enabled: Boolean(session),
    staleTime: 30_000,
    queryFn: () => listOpportunities(filters),
  });
}
