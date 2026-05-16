import { useQuery } from '@tanstack/react-query';
import { fetchMessages } from '~/features/chat/services/chat.service';

export function useMessages(conversationId: string) {
  return useQuery({
    queryKey: ['messages', conversationId],
    queryFn: () => fetchMessages(conversationId),
    enabled: !!conversationId,
    staleTime: 15_000,
  });
}
