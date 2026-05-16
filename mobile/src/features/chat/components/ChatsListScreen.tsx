import { useMemo } from 'react';
import { View, Text, FlatList, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import { useQueries } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { useConversations } from '~/features/chat/hooks/useConversations';
import { useUnreadCounts } from '~/features/chat/hooks/useUnreadCounts';
import { useAuthSession } from '~/features/auth/SessionContext';
import { QueryState } from '~/components/ui/QueryState';
import { ConversationListRow } from './ConversationListRow';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';
import type { ConversationRow } from '~/features/chat/services/chat.service';

type ProfileLite = Pick<
  Database['public']['Tables']['profiles']['Row'],
  'id' | 'name' | 'handle' | 'photo_url'
>;

export function ChatsListScreen() {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const myId = session?.user.id;
  const conversationsQuery = useConversations();
  const conversations: ConversationRow[] =
    conversationsQuery.data?.pages.flatMap((p) => p.rows) ?? [];

  const unreadQuery = useUnreadCounts();
  const unreadByConversation = useMemo(() => {
    const map = new Map<string, number>();
    (unreadQuery.data ?? []).forEach((row) => map.set(row.conversation_id, row.unread_count));
    return map;
  }, [unreadQuery.data]);

  const muteQueries = useQueries({
    queries: conversations.map((c) => ({
      queryKey: ['conversation-muted', myId, c.id],
      enabled: !!myId,
      queryFn: async (): Promise<boolean> => {
        if (!myId) return false;
        const { data, error } = await supabase
          .from('conversation_mutes')
          .select('conversation_id')
          .eq('user_id', myId)
          .eq('conversation_id', c.id)
          .maybeSingle();
        if (error) throw new Error(error.message);
        return data !== null;
      },
      staleTime: 60_000,
    })),
  });

  const peerIds = useMemo(() => {
    if (!myId) return [];
    return conversations.map((c) =>
      c.participant_a_id === myId ? c.participant_b_id : c.participant_a_id
    );
  }, [conversations, myId]);

  const previewQueries = useQueries({
    queries: conversations.map((c) => ({
      queryKey: ['conversation-last-message', c.id],
      queryFn: async (): Promise<string | null> => {
        const { data, error } = await supabase
          .from('messages')
          .select('body')
          .eq('conversation_id', c.id)
          .order('created_at', { ascending: false })
          .limit(1);
        if (error) throw new Error(error.message);
        return data?.[0]?.body ?? null;
      },
      staleTime: 30_000,
    })),
  });

  const peerQueries = useQueries({
    queries: peerIds.map((id) => ({
      queryKey: ['profile-by-id', id],
      queryFn: async (): Promise<ProfileLite | null> => {
        const { data, error } = await supabase
          .from('profiles')
          .select('id, name, handle, photo_url')
          .eq('id', id)
          .single();
        if (error) {
          if (error.code === 'PGRST116') return null;
          throw new Error(error.message);
        }
        return data;
      },
      staleTime: 60_000,
    })),
  });

  return (
    <View className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <View className="pt-16 px-6 pb-4">
          <Text className="text-body text-2xl font-semibold">{t('chat.chatsTitle')}</Text>
        </View>

        <QueryState
          query={conversationsQuery}
          isEmpty={(data) => data.pages.flatMap((p) => p.rows).length === 0}
          emptyFallback={
            <View className="py-12 px-6 items-center">
              <Text className="text-muted text-center">
                No conversations yet. Accept an intro to start chatting.
              </Text>
            </View>
          }
        >
          {(data) => {
            const rows = data.pages.flatMap((p) => p.rows);
            return (
              <FlatList
                testID="chats-list"
                data={rows}
                keyExtractor={(c) => c.id}
                onEndReached={() => {
                  if (conversationsQuery.hasNextPage && !conversationsQuery.isFetchingNextPage) {
                    conversationsQuery.fetchNextPage();
                  }
                }}
                onEndReachedThreshold={0.5}
                ListFooterComponent={
                  conversationsQuery.isFetchingNextPage ? (
                    <View className="py-4 items-center">
                      <ActivityIndicator color="#fff" />
                    </View>
                  ) : null
                }
                renderItem={({ item, index }) => {
                  const peer = peerQueries[index]?.data ?? null;
                  const preview = previewQueries[index]?.data ?? null;
                  const unread = unreadByConversation.get(item.id) ?? 0;
                  const muted = muteQueries[index]?.data ?? false;
                  return (
                    <ConversationListRow
                      peerName={peer?.name ?? '...'}
                      peerHandle={peer?.handle ?? '?'}
                      peerPhotoUrl={peer?.photo_url ?? null}
                      lastMessagePreview={preview}
                      unreadCount={unread}
                      isMuted={muted}
                      onPress={() =>
                        router.push({
                          pathname: '/(app)/chats/[id]',
                          params: { id: item.id },
                        })
                      }
                    />
                  );
                }}
              />
            );
          }}
        </QueryState>
      </View>
    </View>
  );
}
