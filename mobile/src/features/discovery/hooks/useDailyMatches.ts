import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { fetchDailyMatches, todayLocalIso } from '~/features/discovery/services/discovery.service';

export function useDailyMatches() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const date = todayLocalIso();

  return useQuery({
    queryKey: ['daily-matches', userId, date],
    queryFn: () => fetchDailyMatches(date),
    enabled: !!userId,
    staleTime: 5 * 60 * 1000,
  });
}
