import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { InfiniteData } from '@tanstack/react-query';
import { deleteMessage } from '~/features/chat/services/chat.service';
import type { MessageRow } from '~/features/chat/services/chat.service';
import type { MessagesPage } from '~/features/chat/hooks/useMessages';

type Ctx = { previous: InfiniteData<MessagesPage, string | null> | undefined };

export function useDeleteMessage(conversationId: string) {
  const qc = useQueryClient();
  return useMutation<MessageRow, Error, string, Ctx>({
    mutationFn: (id: string) => deleteMessage(id),
    onMutate: async (id) => {
      await qc.cancelQueries({ queryKey: ['messages', conversationId] });
      const previous = qc.getQueryData<InfiniteData<MessagesPage, string | null>>([
        'messages',
        conversationId,
      ]);
      qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
        ['messages', conversationId],
        (prev) => {
          if (!prev) return prev;
          const deletedAt = new Date().toISOString();
          return {
            ...prev,
            pages: prev.pages.map((page) => ({
              ...page,
              rows: page.rows.map((m) =>
                m.id === id ? { ...m, body: null, media_path: null, deleted_at: deletedAt } : m
              ),
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
    onSuccess: (deleted) => {
      qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
        ['messages', conversationId],
        (prev) => {
          if (!prev) return prev;
          return {
            ...prev,
            pages: prev.pages.map((page) => ({
              ...page,
              rows: page.rows.map((m) => (m.id === deleted.id ? deleted : m)),
            })),
          };
        }
      );
    },
  });
}
