import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { fetchDailyMatches } from '~/features/discovery/services/discovery.service';

function todayLocalIso(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function useDailyMatches() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const date = todayLocalIso();

  return useQuery({
    queryKey: ['daily-matches', userId, date],
    queryFn: fetchDailyMatches,
    enabled: !!userId,
    staleTime: 5 * 60 * 1000,
  });
}
