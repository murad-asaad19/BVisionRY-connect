import { useMutation, useQueryClient } from '@tanstack/react-query';
import { proposeMeeting } from '~/features/meetings/services/meetings.service';

export function useProposeMeeting(conversationId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (params: {
      slots: string[];
      durationMinutes: number;
      meetingUrl: string | null;
      timezone: string | null;
    }) =>
      proposeMeeting({
        conversationId,
        slots: params.slots,
        durationMinutes: params.durationMinutes,
        meetingUrl: params.meetingUrl,
        timezone: params.timezone,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['messages', conversationId] });
      qc.invalidateQueries({ queryKey: ['meeting-proposals', conversationId] });
    },
  });
}
