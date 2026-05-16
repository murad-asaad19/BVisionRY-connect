import { useMutation, useQueryClient } from '@tanstack/react-query';
import { deleteMessage } from '~/features/chat/services/chat.service';
import type { MessageRow } from '~/features/chat/services/chat.service';

export function useDeleteMessage(conversationId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => deleteMessage(id),
    onSuccess: (deleted) => {
      qc.setQueryData<MessageRow[]>(['messages', conversationId], (prev) => {
        if (!prev) return prev;
        return prev.map((m) => (m.id === deleted.id ? deleted : m));
      });
    },
  });
}
