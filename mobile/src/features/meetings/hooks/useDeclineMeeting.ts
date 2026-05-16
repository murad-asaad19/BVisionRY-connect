import { useMutation, useQueryClient } from '@tanstack/react-query';
import { declineMeeting } from '~/features/meetings/services/meetings.service';
import type { MeetingProposalRow } from '~/features/meetings/services/meetings.service';

export function useDeclineMeeting(conversationId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (meetingId: string) => declineMeeting(meetingId),
    onSuccess: (updated) => {
      qc.setQueryData<MeetingProposalRow[]>(['meeting-proposals', conversationId], (prev) => {
        if (!prev) return [updated];
        return prev.map((p) => (p.id === updated.id ? updated : p));
      });
    },
  });
}
