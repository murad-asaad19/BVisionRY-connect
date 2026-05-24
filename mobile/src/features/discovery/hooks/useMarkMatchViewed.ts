import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  markMatchViewed,
  todayLocalIso,
  type DailyMatchView,
} from '~/features/discovery/services/discovery.service';

/**
 * Mark a daily-match row as viewed. The mutation:
 *   1. fires the RPC,
 *   2. optimistically patches the cached daily-matches list so the matching
 *      row gains a `viewed_at` value — without this patch the
 *      `DailyMatchesStrip` `useEffect` would re-trigger as soon as React
 *      re-renders with the still-`viewed_at: null` cache, looping the
 *      mutation. The session-scoped `markedRef` in the strip is the first
 *      line of defence; this patch keeps the cache itself honest across
 *      remounts and refetches.
 */
export function useMarkMatchViewed() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const date = todayLocalIso();

  return useMutation({
    mutationFn: (matchId: string) => markMatchViewed(matchId),
    onSuccess: (_data, matchId) => {
      if (!userId) return;
      const key = ['daily-matches', userId, date];
      qc.setQueryData<DailyMatchView[] | undefined>(key, (prev) => {
        if (!prev) return prev;
        const now = new Date().toISOString();
        return prev.map((row) =>
          row.id === matchId && !row.viewed_at ? { ...row, viewed_at: now } : row
        );
      });
    },
  });
}
