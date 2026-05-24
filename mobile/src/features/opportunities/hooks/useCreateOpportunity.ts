import { useMutation, useQueryClient } from '@tanstack/react-query';
import {
  createOpportunity,
  type OpportunityDetail,
} from '~/features/opportunities/services/opportunities.service';
import type { CreateOpportunityInput } from '~/features/opportunities/schemas';

export function useCreateOpportunity() {
  const qc = useQueryClient();
  return useMutation<string, Error, CreateOpportunityInput>({
    mutationFn: createOpportunity,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['opportunities', 'feed'] });
      qc.invalidateQueries({ queryKey: ['opportunities', 'mine'] });
    },
  });
}

export type { OpportunityDetail };
