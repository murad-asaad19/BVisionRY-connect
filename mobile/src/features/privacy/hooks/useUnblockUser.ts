import { useMutation, useQueryClient } from '@tanstack/react-query';
import { unblockUser } from '~/features/privacy/services/privacy.service';

export function useUnblockUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: unblockUser,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['blocked-users'] });
      qc.invalidateQueries({ queryKey: ['daily-matches'] });
      qc.invalidateQueries({ queryKey: ['intros'] });
      qc.invalidateQueries({ queryKey: ['conversations'] });
      qc.invalidateQueries({ queryKey: ['profile'] });
      qc.invalidateQueries({ queryKey: ['feed'] });
      qc.invalidateQueries({ queryKey: ['connections'] });
      qc.invalidateQueries({ queryKey: ['decline-cooldown'] });
    },
  });
}
