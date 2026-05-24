import { useMutation, useQueryClient } from '@tanstack/react-query';
import { cancelBooking } from '~/features/office-hours/services/officeHours.service';

type Vars = { slotId: string; hostId?: string };

/**
 * Cancels a booked office-hours slot. Invalidates the booker's list and
 * the host's upcoming-slots cache (the slot may have reopened > 24h out).
 */
export function useCancelBooking() {
  const qc = useQueryClient();
  return useMutation<void, Error, Vars>({
    mutationFn: ({ slotId }) => cancelBooking(slotId),
    onSuccess: (_void, { hostId }) => {
      qc.invalidateQueries({ queryKey: ['office-hours', 'my-bookings'] });
      if (hostId) {
        qc.invalidateQueries({ queryKey: ['office-hours', 'upcoming-slots', hostId] });
      }
    },
  });
}
