import { useMutation, useQueryClient } from '@tanstack/react-query';
import { closeOpportunity } from '~/features/opportunities/services/opportunities.service';

export function useCloseOpportunity() {
  const qc = useQueryClient();
  return useMutation<void, Error, string>({
    mutationFn: closeOpportunity,
    onSuccess: (_, id) => {
      qc.invalidateQueries({ queryKey: ['opportunities', 'feed'] });
      qc.invalidateQueries({ queryKey: ['opportunities', 'mine'] });
      qc.invalidateQueries({ queryKey: ['opportunities', 'detail', id] });
    },
  });
}
