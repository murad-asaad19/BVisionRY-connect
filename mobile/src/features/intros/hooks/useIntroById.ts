import { useQuery } from '@tanstack/react-query';
import { fetchIntroById } from '~/features/intros/services/intros.service';

export function useIntroById(id: string) {
  return useQuery({
    queryKey: ['intros', 'by-id', id],
    queryFn: () => fetchIntroById(id),
    enabled: !!id,
    staleTime: 30_000,
  });
}
