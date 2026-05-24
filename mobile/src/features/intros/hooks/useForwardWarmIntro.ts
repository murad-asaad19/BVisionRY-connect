import { useMutation, useQueryClient } from '@tanstack/react-query';
import { forwardWarmIntro } from '~/features/intros/services/warmIntros.service';

/**
 * Forward an incoming warm-intro request to the original target.
 *
 * After a successful forward:
 *   * the original warm_request is now `connected` server-side, so
 *     both the inbox prefix and the sent-intros prefix need to refresh
 *     to drop the "pending" state;
 *   * the specific intro's by-id cache needs invalidation so the open
 *     `IntroDetailView` re-renders without the Forward button.
 */
export function useForwardWarmIntro() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: forwardWarmIntro,
    onSuccess: (_newId, variables) => {
      qc.invalidateQueries({ queryKey: ['intros', 'inbox'] });
      qc.invalidateQueries({ queryKey: ['intros', 'sent'] });
      qc.invalidateQueries({ queryKey: ['intros', 'by-id', variables.introId] });
      // Forwarder may now see the original target on their own
      // suggestion list change (target is no longer a 1st-degree
      // suggestion, etc.), so bust the suggestions cache too.
      qc.invalidateQueries({ queryKey: ['warmIntroSuggestions'] });
    },
  });
}
