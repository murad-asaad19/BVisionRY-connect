import { useQuery } from '@tanstack/react-query';
import {
  getOpportunity,
  type OpportunityDetail,
} from '~/features/opportunities/services/opportunities.service';
import { useAuthSession } from '~/features/auth/SessionContext';

export function useOpportunity(id: string | undefined) {
  const { session } = useAuthSession();
  return useQuery<OpportunityDetail>({
    queryKey: ['opportunities', 'detail', id],
    enabled: Boolean(session && id),
    staleTime: 30_000,
    queryFn: () => getOpportunity(id as string),
  });
}
