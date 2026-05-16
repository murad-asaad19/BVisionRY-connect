import { useMutation, useQueryClient } from '@tanstack/react-query';
import { submitFeedback } from '~/features/meetings/services/meetings.service';
import type { Rating } from '~/features/meetings/services/meetings.service';

export function useSubmitFeedback(conversationId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (params: { meetingId: string; rating: Rating; note: string | null }) =>
      submitFeedback(params),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pending-feedback', conversationId] });
    },
  });
}
