import { useQuery } from '@tanstack/react-query';
import { listConnections } from '~/features/connections/services/connections.service';

export function useConnections() {
  return useQuery({
    queryKey: ['connections'],
    queryFn: listConnections,
  });
}
