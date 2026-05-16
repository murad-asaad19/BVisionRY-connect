import { useQuery } from '@tanstack/react-query';
import { listBlockedUsers } from '~/features/privacy/services/privacy.service';

export function useBlockedUsers() {
  return useQuery({
    queryKey: ['blocked-users'],
    queryFn: listBlockedUsers,
  });
}
