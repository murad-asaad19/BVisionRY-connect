import { useMutation, useQueryClient } from '@tanstack/react-query';
import { updateOpportunity } from '~/features/opportunities/services/opportunities.service';
import type { CreateOpportunityInput } from '~/features/opportunities/schemas';

type Vars = { id: string; input: CreateOpportunityInput };

export function useUpdateOpportunity() {
  const qc = useQueryClient();
  return useMutation<void, Error, Vars>({
    mutationFn: ({ id, input }) => updateOpportunity(id, input),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['opportunities', 'feed'] });
      qc.invalidateQueries({ queryKey: ['opportunities', 'mine'] });
      qc.invalidateQueries({ queryKey: ['opportunities', 'detail', id] });
    },
  });
}
