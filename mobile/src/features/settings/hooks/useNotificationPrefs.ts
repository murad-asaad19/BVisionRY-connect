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

function keyOf(kind: NotificationKind, channel: NotificationChannel): string {
  return `${kind}:${channel}`;
}

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

/**
 * Mutation for toggling a single notification preference, with optimistic
 * UI update + automatic rollback on error so the Switch stays in sync with
 * the user's tap even before the network round-trip completes.
 */
export function useSetNotificationPref() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const qc = useQueryClient();
  const queryKey = [...KEY, userId];
  return useMutation({
    mutationFn: async (p: {
      kind: NotificationKind;
      channel: NotificationChannel;
      enabled: boolean;
    }) => {
      if (!userId) throw new Error('not signed in');
      await setNotificationPref({ userId, ...p });
    },
    onMutate: async (p) => {
      await qc.cancelQueries({ queryKey });
      const previous = qc.getQueryData<PrefMap>(queryKey);
      qc.setQueryData<PrefMap>(queryKey, (curr) => ({
        ...(curr ?? {}),
        [keyOf(p.kind, p.channel)]: p.enabled,
      }));
      return { previous };
    },
    onError: (_e, _vars, ctx) => {
      if (ctx?.previous) qc.setQueryData(queryKey, ctx.previous);
    },
    onSettled: () => qc.invalidateQueries({ queryKey }),
  });
}
