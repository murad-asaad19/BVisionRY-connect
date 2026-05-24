import { useQuery } from '@tanstack/react-query';
import {
  listMyOpportunities,
  type MyOpportunityItem,
} from '~/features/opportunities/services/opportunities.service';
import { useAuthSession } from '~/features/auth/SessionContext';

/** Caller's own opportunities — all statuses, newest first. */
export function useMyOpportunities() {
  const { session } = useAuthSession();
  return useQuery<MyOpportunityItem[]>({
    queryKey: ['opportunities', 'mine', session?.user.id],
    enabled: Boolean(session),
    staleTime: 30_000,
    queryFn: listMyOpportunities,
  });
}
