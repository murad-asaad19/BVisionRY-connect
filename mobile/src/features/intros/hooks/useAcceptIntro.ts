import { useMutation, useQueryClient } from '@tanstack/react-query';
import { acceptIntro } from '~/features/intros/services/intros.service';

export function useAcceptIntro() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: acceptIntro,
    onSuccess: (updated) => {
      qc.setQueryData(['intros', 'by-id', updated.id], updated);
      // Broad-prefix invalidation: 'intros' covers both ['intros', 'inbox', id]
      // and ['intros', 'inbox-unread', id]; bare 'conversations' / 'connections'
      // / 'decline-cooldown' bust every per-user variant of those keys. React
      // Query treats queryKey as a prefix unless `exact: true` is set.
      qc.invalidateQueries({ queryKey: ['intros'] });
      qc.invalidateQueries({ queryKey: ['conversations'] });
      qc.invalidateQueries({ queryKey: ['connections'] });
      qc.invalidateQueries({ queryKey: ['decline-cooldown'] });
    },
  });
}
