import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { fetchProfile } from '~/features/profile/services/profile.service';

export function useCurrentUserProfile() {
  const { session } = useAuthSession();
  const userId = session?.user.id;

  return useQuery({
    queryKey: ['profile', userId],
    queryFn: () => fetchProfile(userId!),
    enabled: !!userId,
    staleTime: 60_000,
  });
}
