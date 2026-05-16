import { useMutation, useQueryClient } from '@tanstack/react-query';
import { markConversationRead } from '~/features/chat/services/chat.service';

export function useMarkConversationRead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (conversationId: string) => markConversationRead(conversationId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['conversation-unread'] });
    },
  });
}
