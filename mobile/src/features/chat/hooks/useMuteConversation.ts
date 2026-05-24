import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  isConversationMuted,
  muteConversation,
  unmuteConversation,
} from '~/features/chat/services/chat.service';
import type { ConversationOverviewRow } from '~/features/chat/services/chat.service';

export function useIsConversationMuted(conversationId: string) {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useQuery({
    queryKey: ['conversation-muted', userId, conversationId],
    enabled: !!userId && !!conversationId,
    queryFn: () => isConversationMuted({ userId: userId!, conversationId }),
    staleTime: 60_000,
  });
}

export function useMuteConversation(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  return useMutation<void, Error, boolean>({
    mutationFn: (next: boolean) =>
      next ? muteConversation(conversationId) : unmuteConversation(conversationId),
    onSuccess: (_data, next) => {
      // Per-conversation muted query (still used by ConversationScreen header).
      qc.invalidateQueries({ queryKey: ['conversation-muted', userId, conversationId] });
      // After the overview-RPC fold, `is_muted` lives in the chats list cache;
      // patch it in-place so the row badge updates immediately.
      qc.setQueryData<ConversationOverviewRow[]>(['conversations', userId], (prev) => {
        if (!prev) return prev;
        return prev.map((r) =>
          r.conversation_id === conversationId ? { ...r, is_muted: next } : r
        );
      });
    },
  });
}
