import { useMutation, useQueryClient } from '@tanstack/react-query';
import { bookSlot } from '~/features/office-hours/services/officeHours.service';

type Vars = { hostId: string; slotId: string; topic: string };

/**
 * Books an office-hours slot. Invalidates the host's upcoming-slots cache
 * (the booked slot disappears) and `my_bookings` (the booker's list grows).
 */
export function useBookSlot() {
  const qc = useQueryClient();
  return useMutation<string, Error, Vars>({
    mutationFn: ({ slotId, topic }) => bookSlot(slotId, topic),
    onSuccess: (_proposalId, { hostId }) => {
      qc.invalidateQueries({ queryKey: ['office-hours', 'upcoming-slots', hostId] });
      qc.invalidateQueries({ queryKey: ['office-hours', 'my-bookings'] });
      // Meeting message bubbles will appear in the chat with the host.
      qc.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}
