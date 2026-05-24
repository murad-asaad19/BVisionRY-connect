import { useMutation, useQueryClient } from '@tanstack/react-query';
import { expressInterest } from '~/features/opportunities/services/opportunities.service';

type Vars = { opportunityId: string; note?: string };

export function useExpressInterest() {
  const qc = useQueryClient();
  return useMutation<void, Error, Vars>({
    mutationFn: ({ opportunityId, note }) => expressInterest(opportunityId, note),
    onSuccess: (_, { opportunityId }) => {
      qc.invalidateQueries({ queryKey: ['opportunities', 'detail', opportunityId] });
      // Feed includes the interested_count, so refresh that too.
      qc.invalidateQueries({ queryKey: ['opportunities', 'feed'] });
    },
  });
}
