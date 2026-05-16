import { useMutation, useQueryClient } from '@tanstack/react-query';
import { updateNotificationPrefs } from '~/features/settings/services/settings.service';

export function useUpdateNotificationPrefs(userId: string | undefined) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (patch: {
      notify_intro?: boolean;
      notify_message?: boolean;
      notify_meeting?: boolean;
    }) => {
      if (!userId) throw new Error('not signed in');
      await updateNotificationPrefs(userId, patch);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['profile'] }),
  });
}
