import { useInfiniteQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { fetchConversationsPage } from '~/features/chat/services/chat.service';

const PAGE_SIZE = 20;
const INITIAL_CURSOR = '9999-12-31T00:00:00Z';

export function useConversations() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useInfiniteQuery({
    queryKey: ['conversations', userId],
    enabled: !!userId,
    initialPageParam: INITIAL_CURSOR,
    queryFn: ({ pageParam }) =>
      fetchConversationsPage({
        userId: userId!,
        cursor: pageParam as string,
        pageSize: PAGE_SIZE,
      }),
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    staleTime: 15_000,
  });
}
