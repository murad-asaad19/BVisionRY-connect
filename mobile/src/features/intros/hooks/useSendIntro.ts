import { useMutation, useQueryClient } from '@tanstack/react-query';
import { sendIntro } from '~/features/intros/services/intros.service';
import { useAuthSession } from '~/features/auth/SessionContext';

export function useSendIntro() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useMutation({
    mutationFn: sendIntro,
    onSuccess: (sent) => {
      qc.invalidateQueries({ queryKey: ['intros', 'sent', userId] });
      // Today's outbound count changed → refresh the recipient-side daily-cap
      // banner (server-truth) and any other dependents.
      qc.invalidateQueries({ queryKey: ['intros', 'today-count'] });
      // The recipient profile's cooldown probe is keyed by (myId, recipientId);
      // invalidate the whole family so the discover/profile UI stays in sync.
      qc.invalidateQueries({ queryKey: ['decline-cooldown'] });
      qc.setQueryData(['intros', 'by-id', sent.id], sent);
    },
  });
}
