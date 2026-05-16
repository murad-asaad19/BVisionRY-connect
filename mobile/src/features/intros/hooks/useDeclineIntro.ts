import { useMutation, useQueryClient } from '@tanstack/react-query';
import { declineIntro } from '~/features/intros/services/intros.service';
import { useAuthSession } from '~/features/auth/SessionContext';

export function useDeclineIntro() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useMutation({
    mutationFn: declineIntro,
    onSuccess: (updated) => {
      qc.setQueryData(['intros', 'by-id', updated.id], updated);
      qc.invalidateQueries({ queryKey: ['intros', 'inbox', userId] });
    },
  });
}
