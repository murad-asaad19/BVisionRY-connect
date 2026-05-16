import { useMutation, useQueryClient } from '@tanstack/react-query';
import { sendIntro } from '~/features/intros/services/intros.service';
import { useAuthSession } from '~/features/auth/SessionContext';

export function useSendIntro() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useMutation({
    mutationFn: sendIntro,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['intros', 'sent', userId] });
    },
  });
}
