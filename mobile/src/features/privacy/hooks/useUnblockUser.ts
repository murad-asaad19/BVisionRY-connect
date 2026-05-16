import { useMutation, useQueryClient } from '@tanstack/react-query';
import { unblockUser } from '~/features/privacy/services/privacy.service';

export function useUnblockUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: unblockUser,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['blocked-users'] });
      qc.invalidateQueries({ queryKey: ['daily-matches'] });
    },
  });
}
