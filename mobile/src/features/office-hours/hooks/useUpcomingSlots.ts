import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  listUpcomingSlots,
  type UpcomingSlot,
} from '~/features/office-hours/services/officeHours.service';

/**
 * Loads open slots for a host over the next 14 days. Returns [] when the
 * host hasn't enabled office hours (the RPC returns nothing in that case).
 */
export function useUpcomingSlots(hostId: string | undefined) {
  const { session } = useAuthSession();
  return useQuery<UpcomingSlot[]>({
    queryKey: ['office-hours', 'upcoming-slots', hostId],
    enabled: Boolean(session && hostId),
    staleTime: 30_000,
    queryFn: () => listUpcomingSlots(hostId as string),
  });
}
