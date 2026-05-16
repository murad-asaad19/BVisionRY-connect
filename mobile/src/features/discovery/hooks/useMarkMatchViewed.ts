import { useMutation } from '@tanstack/react-query';
import { markMatchViewed } from '~/features/discovery/services/discovery.service';

export function useMarkMatchViewed() {
  return useMutation({
    mutationFn: (matchId: string) => markMatchViewed(matchId),
  });
}
