import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  fetchMeetingProposals,
  fetchMyFeedbackForMeeting,
} from '~/features/meetings/services/meetings.service';
import type { MeetingProposalRow } from '~/features/meetings/services/meetings.service';

/**
 * Returns confirmed meeting proposals whose end time has passed AND for which
 * the current user has not yet submitted feedback.
 */
export function usePendingFeedback(conversationId: string) {
  const { session } = useAuthSession();
  const userId = session?.user.id;

  return useQuery({
    queryKey: ['pending-feedback', conversationId, userId],
    enabled: !!conversationId && !!userId,
    staleTime: 60_000,
    queryFn: async (): Promise<MeetingProposalRow[]> => {
      const all = await fetchMeetingProposals(conversationId);
      const now = Date.now();
      const past = all.filter((m) => {
        if (m.state !== 'confirmed') return false;
        if (!m.confirmed_slot) return false;
        const end = new Date(m.confirmed_slot).getTime() + m.duration_minutes * 60_000;
        return end < now;
      });
      const results = await Promise.all(
        past.map(async (m) => {
          const fb = await fetchMyFeedbackForMeeting(m.id, userId!);
          return fb ? null : m;
        })
      );
      return results.filter((m): m is MeetingProposalRow => m !== null);
    },
  });
}
