import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { updateProfile, type ProfileUpdate } from '~/features/profile/services/profile.service';

export function useUpdateProfile() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const qc = useQueryClient();

  return useMutation({
    mutationFn: (patch: ProfileUpdate) => {
      if (!userId) throw new Error('Not authenticated');
      return updateProfile(userId, patch);
    },
    onSuccess: (data) => {
      qc.setQueryData(['profile', userId], data);
    },
  });
}
