import { useEffect, useMemo, useRef } from 'react';
import { View, Text, FlatList, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useMessages } from '~/features/chat/hooks/useMessages';
import { useMessagesRealtime } from '~/features/chat/hooks/useMessagesRealtime';
import { useMarkConversationRead } from '~/features/chat/hooks/useMarkConversationRead';
import { useTypingChannel } from '~/features/chat/hooks/useTypingChannel';
import {
  useIsConversationMuted,
  useMuteConversation,
} from '~/features/chat/hooks/useMuteConversation';
import { useMeetingProposals } from '~/features/meetings/hooks/useMeetingProposals';
import { useMeetingProposalsRealtime } from '~/features/meetings/hooks/useMeetingProposalsRealtime';
import { QueryState } from '~/components/ui/QueryState';
import { MessageBubble } from './MessageBubble';
import { MessageComposer } from './MessageComposer';
import { PostMeetingPrompt } from '~/features/meetings/components/PostMeetingPrompt';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

type ConversationRow = Database['public']['Tables']['conversations']['Row'];
type ProfileLite = Pick<
  Database['public']['Tables']['profiles']['Row'],
  'id' | 'name' | 'handle' | 'photo_url'
>;

function useConversationById(id: string) {
  return useQuery({
    queryKey: ['conversation-by-id', id],
    enabled: !!id,
    staleTime: 60_000,
    queryFn: async (): Promise<ConversationRow | null> => {
      const { data, error } = await supabase
        .from('conversations')
        .select('*')
        .eq('id', id)
        .single();
      if (error) {
        if (error.code === 'PGRST116') return null;
        throw new Error(error.message);
      }
      return data;
    },
  });
}

function usePeerProfile(id: string | null) {
  return useQuery({
    queryKey: ['profile-by-id', id],
    enabled: !!id,
    staleTime: 60_000,
    queryFn: async (): Promise<ProfileLite | null> => {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, handle, photo_url')
        .eq('id', id!)
        .single();
      if (error) {
        if (error.code === 'PGRST116') return null;
        throw new Error(error.message);
      }
      return data;
    },
  });
}

type Props = { id: string };

export function ConversationScreen({ id }: Props) {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const myId = session?.user.id ?? '';

  useMessagesRealtime(id);
  useMeetingProposalsRealtime(id);

  const conversationQuery = useConversationById(id);
  const messagesQuery = useMessages(id);
  const proposalsQuery = useMeetingProposals(id);

  const markReadMutation = useMarkConversationRead();
  const mutedQuery = useIsConversationMuted(id);
  const muteMutation = useMuteConversation(id);
  const { isOtherTyping, sendTyping } = useTypingChannel(id, myId || undefined);

  const peerId = useMemo(() => {
    const conv = conversationQuery.data;
    if (!conv || !myId) return null;
    return conv.participant_a_id === myId ? conv.participant_b_id : conv.participant_a_id;
  }, [conversationQuery.data, myId]);

  const peerQuery = usePeerProfile(peerId);
  const peer = peerQuery.data;

  const proposalsById = useMemo(() => {
    const map = new Map<string, NonNullable<typeof proposalsQuery.data>[number]>();
    (proposalsQuery.data ?? []).forEach((p) => map.set(p.id, p));
    return map;
  }, [proposalsQuery.data]);

  const listRef = useRef<FlatList>(null);
  const messagesLength = messagesQuery.data?.length ?? 0;
  useEffect(() => {
    if (messagesLength > 0) {
      requestAnimationFrame(() => listRef.current?.scrollToEnd({ animated: true }));
    }
  }, [messagesLength]);

  // Mark read on mount + every time messages arrive
  useEffect(() => {
    if (!id || !myId) return;
    markReadMutation.mutate(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, myId, messagesLength]);

  const isMuted = mutedQuery.data === true;

  return (
    <View className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <View className="bg-white px-3 pt-3.5 pb-2.5 border-b border-border flex-row items-center gap-2">
          <Pressable
            testID="conversation-back"
            onPress={() => router.back()}
            accessibilityRole="button"
            accessibilityLabel="Back"
            className="px-2 py-1"
          >
            <Text className="text-navy text-base">←</Text>
          </Pressable>
          <AvatarCircle name={peer?.name ?? '?'} photoUrl={peer?.photo_url ?? null} size={32} />
          <View className="flex-1 min-w-0 ml-1">
            <Text
              testID="conversation-peer-name"
              numberOfLines={1}
              className="font-display-bold text-[14px] text-navy"
            >
              {peer?.name ?? '...'}
            </Text>
            <Text numberOfLines={1} className="font-body text-[11px] text-muted">
              @{peer?.handle ?? '?'}
            </Text>
          </View>
          <Pressable
            testID="conversation-mute-toggle"
            accessibilityRole="button"
            accessibilityLabel={isMuted ? t('chat.unmute') : t('chat.mute')}
            onPress={() => muteMutation.mutate(!isMuted)}
            disabled={muteMutation.isPending}
            className="px-2 py-1"
          >
            <Text className="text-muted text-lg">{isMuted ? '🔇' : '🔔'}</Text>
          </Pressable>
        </View>

        <QueryState
          query={messagesQuery}
          isEmpty={(data) => data.length === 0}
          emptyFallback={
            <View className="flex-1 items-center justify-center px-6">
              <Text className="text-muted text-center">No messages yet. Say hi!</Text>
            </View>
          }
        >
          {(rows) => (
            <FlatList
              ref={listRef}
              testID="messages-list"
              data={rows}
              keyExtractor={(m) => m.id}
              contentContainerStyle={{ paddingHorizontal: 16, paddingVertical: 8 }}
              renderItem={({ item }) => {
                const proposal = item.meeting_proposal_id
                  ? (proposalsById.get(item.meeting_proposal_id) ?? null)
                  : null;
                return (
                  <MessageBubble
                    message={item}
                    isMine={item.sender_id === myId}
                    proposal={proposal}
                    conversationId={id}
                    myId={myId}
                    peerHandle={peer?.handle ?? null}
                  />
                );
              }}
              onContentSizeChange={() => listRef.current?.scrollToEnd({ animated: false })}
            />
          )}
        </QueryState>

        {isOtherTyping && (
          <View testID="conversation-typing-indicator" className="px-6 py-1">
            <Text className="text-muted text-xs italic">
              {peer?.name ?? '...'} {t('chat.typing')}
            </Text>
          </View>
        )}

        <MessageComposer conversationId={id} onTyping={sendTyping} />
        <PostMeetingPrompt conversationId={id} />
      </View>
    </View>
  );
}
