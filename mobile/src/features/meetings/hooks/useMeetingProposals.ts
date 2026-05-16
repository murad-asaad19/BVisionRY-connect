import { useQuery } from '@tanstack/react-query';
import { fetchMeetingProposals } from '~/features/meetings/services/meetings.service';

export function useMeetingProposals(conversationId: string) {
  return useQuery({
    queryKey: ['meeting-proposals', conversationId],
    queryFn: () => fetchMeetingProposals(conversationId),
    enabled: !!conversationId,
    staleTime: 30_000,
  });
}
