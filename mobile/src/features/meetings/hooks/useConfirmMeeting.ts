import { useMutation, useQueryClient } from '@tanstack/react-query';
import { confirmMeeting } from '~/features/meetings/services/meetings.service';
import type { MeetingProposalRow } from '~/features/meetings/services/meetings.service';

export function useConfirmMeeting(conversationId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (params: { meetingId: string; slot: string }) =>
      confirmMeeting(params.meetingId, params.slot),
    onSuccess: (updated) => {
      qc.setQueryData<MeetingProposalRow[]>(['meeting-proposals', conversationId], (prev) => {
        if (!prev) return [updated];
        return prev.map((p) => (p.id === updated.id ? updated : p));
      });
      qc.invalidateQueries({ queryKey: ['messages', conversationId] });
      qc.invalidateQueries({ queryKey: ['pending-meeting-reviews'] });
    },
  });
}
