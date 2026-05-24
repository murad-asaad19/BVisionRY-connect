import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  getMyOfficeHoursSettings,
  type OfficeHoursSettings,
} from '~/features/office-hours/services/officeHours.service';

/**
 * Loads the caller's own office-hours settings. Returns a default-empty
 * row if no settings row exists yet (the RPC handles the empty case).
 */
export function useOfficeHoursSettings() {
  const { session } = useAuthSession();
  return useQuery<OfficeHoursSettings>({
    queryKey: ['office-hours', 'settings', session?.user.id],
    enabled: Boolean(session),
    staleTime: 60_000,
    queryFn: getMyOfficeHoursSettings,
  });
}
