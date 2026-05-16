import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { listConversationUnread } from '~/features/chat/services/chat.service';

export function useUnreadCounts() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useQuery({
    queryKey: ['conversation-unread', userId],
    enabled: !!userId,
    queryFn: () => listConversationUnread(),
    staleTime: 15_000,
  });
}
