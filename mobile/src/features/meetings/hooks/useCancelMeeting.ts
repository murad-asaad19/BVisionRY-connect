import { useMutation, useQueryClient } from '@tanstack/react-query';
import { cancelMeeting } from '~/features/meetings/services/meetings.service';
import type { MeetingProposalRow } from '~/features/meetings/services/meetings.service';

/**
 * Proposer-only meeting cancellation. Optimistically updates the
 * ['meeting-proposals', conversationId] cache with the returned row and
 * invalidates the messages list (the meeting message bubble re-renders with
 * the new state).
 */
export function useCancelMeeting(conversationId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (meetingId: string) => cancelMeeting(meetingId),
    onSuccess: (updated) => {
      qc.setQueryData<MeetingProposalRow[]>(['meeting-proposals', conversationId], (prev) => {
        if (!prev) return [updated];
        return prev.map((p) => (p.id === updated.id ? updated : p));
      });
      qc.invalidateQueries({ queryKey: ['messages', conversationId] });
      // Cancelling a 'proposed' meeting can't itself produce a pending review
      // (only 'confirmed' meetings ever do), but cancellation may follow
      // confirm-then-cancel race conditions; broad-prefix invalidate so the
      // post-meeting prompt re-syncs with server truth.
      qc.invalidateQueries({ queryKey: ['pending-meeting-reviews'] });
    },
  });
}
