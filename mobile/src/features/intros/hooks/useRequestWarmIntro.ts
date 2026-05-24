import { useMutation, useQueryClient } from '@tanstack/react-query';
import { sendWarmRequest } from '~/features/intros/services/warmIntros.service';
import { useAuthSession } from '~/features/auth/SessionContext';

/**
 * Send a warm-intro request to the chosen mutual. On success we
 * invalidate:
 *   * the warm-intro suggestions list — the target is now off the
 *     list (any-intros-row exclusion in suggest_warm_intros);
 *   * the viewer's sent-intros tab (the warm_request shows there);
 *   * the inbox prefix (the mutual's inbox gains a new card; the
 *     viewer's own inbox may receive a warm_forward eventually).
 */
export function useRequestWarmIntro() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;

  return useMutation({
    mutationFn: sendWarmRequest,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['warmIntroSuggestions'] });
      qc.invalidateQueries({ queryKey: ['intros', 'sent', userId] });
      qc.invalidateQueries({ queryKey: ['intros', 'today-count'] });
      qc.invalidateQueries({ queryKey: ['inbox'] });
    },
  });
}
