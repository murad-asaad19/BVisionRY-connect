import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { markConversationRead } from '~/features/chat/services/chat.service';
import type { ConversationOverviewRow } from '~/features/chat/services/chat.service';

/**
 * Marks a conversation read on the server, then refreshes the unread cache
 * and zeroes the badge in the chats overview optimistically so the UI
 * reflects the change before the next refetch.
 *
 * NB: the underlying `mark_conversation_read` RPC short-circuits when the
 * caller has `read_receipts_enabled=false`. In that case the peer never
 * sees a read marker, but the local cache update here is still valid for
 * the caller's own view.
 */
export function useMarkConversationRead() {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;

  return useMutation({
    mutationFn: (conversationId: string) => markConversationRead(conversationId),
    onSuccess: (_data, conversationId) => {
      qc.invalidateQueries({ queryKey: ['conversation-unread', userId] });
      qc.setQueryData<ConversationOverviewRow[]>(['conversations', userId], (prev) => {
        if (!prev) return prev;
        return prev.map((r) =>
          r.conversation_id === conversationId ? { ...r, unread_count: 0 } : r
        );
      });
    },
  });
}
