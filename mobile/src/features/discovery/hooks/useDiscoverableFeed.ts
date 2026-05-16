import { useInfiniteQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { fetchFeedPage } from '~/features/discovery/services/discovery.service';
import { useFeedFiltersStore } from '~/features/discovery/store/feedFiltersStore';

const PAGE_SIZE = 20;
const INITIAL_CURSOR = '9999-12-31T00:00:00Z';

export function useDiscoverableFeed() {
  const { session } = useAuthSession();
  const userId = session?.user.id;

  // Select each filter field individually so Zustand's default Object.is
  // equality avoids re-renders unless the actual value changes. Selecting
  // an object literal would trigger an infinite loop.
  const query = useFeedFiltersStore((s) => s.query);
  const roles = useFeedFiltersStore((s) => s.roles);
  const goalTypes = useFeedFiltersStore((s) => s.goalTypes);
  const country = useFeedFiltersStore((s) => s.country);

  return useInfiniteQuery({
    queryKey: ['feed', userId, query, roles.join(','), goalTypes.join(','), country],
    enabled: !!userId,
    initialPageParam: INITIAL_CURSOR,
    queryFn: ({ pageParam }) =>
      fetchFeedPage({
        currentUserId: userId!,
        cursor: pageParam as string,
        pageSize: PAGE_SIZE,
        filters: { query, roles, goalTypes, country },
      }),
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    staleTime: 60_000,
  });
}
