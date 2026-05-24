import { useCallback } from 'react';
import { View, Text, FlatList, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { colors } from '~/theme/colors';
import { useConversations } from '~/features/chat/hooks/useConversations';
import { QueryState } from '~/components/ui/QueryState';
import { ConversationListRow } from './ConversationListRow';
import type { ConversationOverviewRow } from '~/features/chat/services/chat.service';

/**
 * Chats list — backed by `list_conversation_overview` (one RPC call,
 * folding peer profile + last message preview + unread + mute status).
 * The previous implementation issued three per-row queries plus the
 * conversation page query, creating an O(N) round-trip per render.
 */
export function ChatsListScreen() {
  const { t } = useTranslation();
  const conversationsQuery = useConversations();

  const handleRowPress = useCallback((id: string) => {
    router.push({ pathname: '/(app)/chats/[id]', params: { id } });
  }, []);

  const renderItem = useCallback(
    ({ item }: { item: ConversationOverviewRow }) => (
      <ConversationListRow
        peerName={item.peer_name ?? '...'}
        peerHandle={item.peer_handle ?? '?'}
        peerPhotoUrl={item.peer_photo_url}
        lastMessagePreview={item.last_message_body}
        lastMessageKind={item.last_message_kind}
        unreadCount={item.unread_count}
        isMuted={item.is_muted}
        onPress={() => handleRowPress(item.conversation_id)}
      />
    ),
    [handleRowPress]
  );

  return (
    <View className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <View className="pt-16 px-6 pb-4">
          <Text className="text-body text-2xl font-semibold">{t('chat.chatsTitle')}</Text>
        </View>

        <QueryState
          query={conversationsQuery}
          isEmpty={(data) => data.length === 0}
          emptyFallback={
            <View className="py-12 px-6 items-center">
              <Text className="text-muted text-center">
                No conversations yet. Accept an intro to start chatting.
              </Text>
            </View>
          }
        >
          {(rows) => (
            <FlatList<ConversationOverviewRow>
              testID="chats-list"
              data={rows}
              keyExtractor={(c) => c.conversation_id}
              renderItem={renderItem}
              ListFooterComponent={
                conversationsQuery.isFetching && !conversationsQuery.isLoading ? (
                  <View className="py-4 items-center">
                    <ActivityIndicator color={colors.navy} />
                  </View>
                ) : null
              }
            />
          )}
        </QueryState>
      </View>
    </View>
  );
}
