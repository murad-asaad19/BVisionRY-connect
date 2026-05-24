import { useQuery } from '@tanstack/react-query';
import { getProfileSignals, type ProfileSignals } from '~/features/profile/services/profileSignals.service';
import { useAuthSession } from '~/features/auth/SessionContext';

/**
 * Fetch the mutual-connection count + meeting-review average for a
 * target profile. Only runs when there is an authenticated session —
 * the underlying RPC raises 'unauthenticated' for anon callers, so
 * gating here avoids surfacing an error to anon viewers of the public
 * profile page.
 *
 * 5-minute staleTime: signals tick over slowly (connection counts
 * change on intro acceptance, ratings change after a meeting ends) so
 * refetching aggressively is wasted bandwidth.
 */
export function useProfileSignals(targetUserId: string | undefined | null) {
  const { session } = useAuthSession();
  const enabled = Boolean(targetUserId) && Boolean(session);

  return useQuery<ProfileSignals>({
    queryKey: ['profileSignals', targetUserId],
    queryFn: () => getProfileSignals(targetUserId as string),
    enabled,
    staleTime: 5 * 60 * 1000,
  });
}
