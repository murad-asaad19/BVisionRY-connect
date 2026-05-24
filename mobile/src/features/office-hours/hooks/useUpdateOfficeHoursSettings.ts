import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  setOfficeHours,
  type OfficeHoursSettings,
} from '~/features/office-hours/services/officeHours.service';
import type { OfficeHoursSettingsInput } from '~/features/office-hours/schemas';

/**
 * Upserts the caller's office-hours settings and invalidates the cached
 * self-settings row plus any cached `list_upcoming_slots(self)` (the
 * server re-materializes slots inside the RPC).
 */
export function useUpdateOfficeHoursSettings() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useMutation<OfficeHoursSettings, Error, OfficeHoursSettingsInput>({
    mutationFn: (input) => setOfficeHours(input),
    onSuccess: (data) => {
      qc.setQueryData(['office-hours', 'settings', userId], data);
      if (userId) {
        qc.invalidateQueries({ queryKey: ['office-hours', 'upcoming-slots', userId] });
      }
    },
  });
}
