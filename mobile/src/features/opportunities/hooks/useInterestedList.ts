import { useQuery } from '@tanstack/react-query';
import {
  listInterested,
  type InterestedUser,
} from '~/features/opportunities/services/opportunities.service';

type Args = {
  opportunityId: string | undefined;
  /** Only enabled for the opportunity's author — the RPC raises 42501 otherwise. */
  isAuthor: boolean;
};

export function useInterestedList({ opportunityId, isAuthor }: Args) {
  return useQuery<InterestedUser[]>({
    queryKey: ['opportunities', 'interested', opportunityId],
    enabled: Boolean(opportunityId && isAuthor),
    staleTime: 30_000,
    queryFn: () => listInterested(opportunityId as string),
  });
}
