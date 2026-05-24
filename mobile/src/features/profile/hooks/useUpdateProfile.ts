import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  updateProfile,
  type Profile,
  type ProfileUpdate,
} from '~/features/profile/services/profile.service';

type MutationContext = { previousHandle: string | null };

export function useUpdateProfile() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const qc = useQueryClient();

  return useMutation<Profile, Error, ProfileUpdate, MutationContext>({
    mutationFn: (patch: ProfileUpdate) => {
      if (!userId) throw new Error('Not authenticated');
      return updateProfile(userId, patch);
    },
    // The patch only carries the NEW handle. To invalidate the stale
    // `['profile-by-handle', oldHandle]` cache entry after a rename we capture
    // the previous handle from the cached profile before the mutation runs.
    onMutate: () => {
      const cached = qc.getQueryData<Profile>(['profile', userId]);
      return { previousHandle: cached?.handle ?? null };
    },
    onSuccess: (data, _patch, context) => {
      qc.setQueryData(['profile', userId], data);

      const newHandle = data.handle?.toLowerCase() ?? null;
      const oldHandle = context?.previousHandle?.toLowerCase() ?? null;

      // Prime the new handle's cache entry so the next visit doesn't refetch.
      if (newHandle) {
        qc.setQueryData(['profile-by-handle', newHandle], data);
      }

      // Drop the stale entry when the handle actually changed.
      if (oldHandle && newHandle && oldHandle !== newHandle) {
        qc.removeQueries({ queryKey: ['profile-by-handle', oldHandle], exact: true });
      }

      // Sweep any other in-flight consumers that may have cached the old shape.
      qc.invalidateQueries({ queryKey: ['profile-by-handle'] });
    },
  });
}
