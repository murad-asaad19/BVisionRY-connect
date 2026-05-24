import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  listMyBookings,
  type MyBooking,
} from '~/features/office-hours/services/officeHours.service';

/**
 * Slots the caller has booked. Cached at the user level so it's shared
 * across the bookings list + cancel-button entry points.
 */
export function useMyBookings() {
  const { session } = useAuthSession();
  return useQuery<MyBooking[]>({
    queryKey: ['office-hours', 'my-bookings', session?.user.id],
    enabled: Boolean(session),
    staleTime: 30_000,
    queryFn: listMyBookings,
  });
}
