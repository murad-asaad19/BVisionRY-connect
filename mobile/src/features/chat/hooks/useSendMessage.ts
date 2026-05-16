import { useMutation, useQueryClient } from '@tanstack/react-query';
import { sendMessage } from '~/features/chat/services/chat.service';
import { useAuthSession } from '~/features/auth/SessionContext';
import type { MessageRow } from '~/features/chat/services/chat.service';

export function useSendMessage(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const senderId = session?.user.id;

  return useMutation({
    mutationFn: (body: string) => {
      if (!senderId) throw new Error('Not authenticated');
      return sendMessage({ conversationId, senderId, body });
    },
    onSuccess: (newMsg) => {
      qc.setQueryData<MessageRow[]>(['messages', conversationId], (prev) => {
        if (!prev) return [newMsg];
        if (prev.some((m) => m.id === newMsg.id)) return prev;
        return [...prev, newMsg];
      });
      qc.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}
