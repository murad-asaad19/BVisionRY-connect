import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import {
  isConversationMuted,
  muteConversation,
  unmuteConversation,
} from '~/features/chat/services/chat.service';

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
  return useMutation({
    mutationFn: (next: boolean) =>
      next ? muteConversation(conversationId) : unmuteConversation(conversationId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['conversation-muted', userId, conversationId] });
    },
  });
}
