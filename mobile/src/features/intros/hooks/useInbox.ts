import { useInfiniteQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { fetchInboxPage } from '~/features/intros/services/intros.service';

const PAGE_SIZE = 20;

export function useInbox() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useInfiniteQuery({
    queryKey: ['intros', 'inbox', userId],
    enabled: !!userId,
    initialPageParam: null as string | null,
    queryFn: ({ pageParam }) =>
      fetchInboxPage({ userId: userId!, cursor: pageParam, pageSize: PAGE_SIZE }),
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    staleTime: 30_000,
  });
}
