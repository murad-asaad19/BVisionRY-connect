import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  fetchConversationsOverview,
  type ConversationOverviewRow,
} from '~/features/chat/services/chat.service';

/**
 * Returns the full chats overview (peer profile, last message preview,
 * unread + mute status) in a single RPC, removing the per-row N+1 the
 * previous implementation issued (3 queries × N conversations).
 */
export function useConversations() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useQuery<ConversationOverviewRow[]>({
    queryKey: ['conversations', userId],
    enabled: !!userId,
    queryFn: () => fetchConversationsOverview(userId!),
    staleTime: 15_000,
  });
}
