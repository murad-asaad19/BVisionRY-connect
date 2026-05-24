import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { InfiniteData } from '@tanstack/react-query';
import { editMessage } from '~/features/chat/services/chat.service';
import type { MessageRow } from '~/features/chat/services/chat.service';
import type { MessagesPage } from '~/features/chat/hooks/useMessages';

type Vars = { id: string; body: string };
type Ctx = { previous: InfiniteData<MessagesPage, string | null> | undefined };

export function useEditMessage(conversationId: string) {
  const qc = useQueryClient();
  return useMutation<MessageRow, Error, Vars, Ctx>({
    mutationFn: (params: Vars) => editMessage(params),
    onMutate: async ({ id, body }) => {
      await qc.cancelQueries({ queryKey: ['messages', conversationId] });
      const previous = qc.getQueryData<InfiniteData<MessagesPage, string | null>>([
        'messages',
        conversationId,
      ]);
      qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
        ['messages', conversationId],
        (prev) => {
          if (!prev) return prev;
          const editedAt = new Date().toISOString();
          return {
            ...prev,
            pages: prev.pages.map((page) => ({
              ...page,
              rows: page.rows.map((m) => (m.id === id ? { ...m, body, edited_at: editedAt } : m)),
            })),
          };
        }
      );
      return { previous };
    },
    onError: (_err, _vars, ctx) => {
      if (!ctx) return;
      qc.setQueryData(['messages', conversationId], ctx.previous);
    },
    onSuccess: (updated) => {
      qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
        ['messages', conversationId],
        (prev) => {
          if (!prev) return prev;
          return {
            ...prev,
            pages: prev.pages.map((page) => ({
              ...page,
              rows: page.rows.map((m) => (m.id === updated.id ? updated : m)),
            })),
          };
        }
      );
    },
  });
}
