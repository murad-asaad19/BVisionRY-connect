import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  fetchNotificationPrefs,
  setNotificationPref,
  type NotificationChannel,
  type NotificationKind,
  type PrefMap,
} from '~/features/settings/services/notificationPrefs.service';

const KEY = ['notification-prefs'];

export function useNotificationPrefs() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useQuery<PrefMap>({
    queryKey: [...KEY, userId],
    enabled: !!userId,
    queryFn: () => fetchNotificationPrefs(userId!),
    staleTime: 60_000,
  });
}

export function useSetNotificationPref() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (p: {
      kind: NotificationKind;
      channel: NotificationChannel;
      enabled: boolean;
    }) => {
      if (!userId) throw new Error('not signed in');
      await setNotificationPref({ userId, ...p });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: KEY }),
  });
}
