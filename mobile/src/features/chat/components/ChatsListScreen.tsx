import { useCallback } from 'react';
import { View, FlatList, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { MessageSquare } from 'lucide-react-native';
import { colors } from '~/theme/colors';
import { useConversations } from '~/features/chat/hooks/useConversations';
import { QueryState } from '~/components/ui/QueryState';
import { TopBar } from '~/components/ui/TopBar';
import { EmptyState } from '~/components/ui/EmptyState';
import { SkeletonConversationRow } from '~/components/ui/Skeleton';
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
        <TopBar title={t('chat.list.title')} />

        <QueryState
          query={conversationsQuery}
          isEmpty={(data) => data.length === 0}
          loadingFallback={
            <View className="pt-3">
              <SkeletonConversationRow count={6} />
            </View>
          }
          emptyFallback={
            <EmptyState
              icon={MessageSquare}
              title={t('chat.list.emptyTitle')}
              body={t('chat.list.emptyBody')}
            />
          }
        >
          {(rows) => (
            <FlatList<ConversationOverviewRow>
              testID="chats-list"
              data={rows}
              keyExtractor={(c) => c.conversation_id}
              renderItem={renderItem}
              contentContainerStyle={{ paddingTop: 12 }}
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
