import { useMutation, useQueryClient } from '@tanstack/react-query';
import { editMessage } from '~/features/chat/services/chat.service';
import type { MessageRow } from '~/features/chat/services/chat.service';

export function useEditMessage(conversationId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (params: { id: string; body: string }) => editMessage(params),
    onSuccess: (updated) => {
      qc.setQueryData<MessageRow[]>(['messages', conversationId], (prev) => {
        if (!prev) return prev;
        return prev.map((m) => (m.id === updated.id ? updated : m));
      });
    },
  });
}
