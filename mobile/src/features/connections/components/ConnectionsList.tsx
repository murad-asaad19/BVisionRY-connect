import { View, Text, Pressable, FlatList } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Users } from 'lucide-react-native';
import { useConnections } from '~/features/connections/hooks/useConnections';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { QueryState } from '~/components/ui/QueryState';
import { EmptyState } from '~/components/ui/EmptyState';
import { SkeletonConversationRow } from '~/components/ui/Skeleton';

export function ConnectionsList() {
  const { t } = useTranslation();
  const q = useConnections();
  return (
    <QueryState
      query={q}
      loadingFallback={
        <View className="pt-3">
          <SkeletonConversationRow count={5} />
        </View>
      }
      isEmpty={(rows) => rows.length === 0}
      emptyFallback={
        <EmptyState
          testID="connections-empty"
          icon={Users}
          title={t('network.empty.title')}
          body={t('connections.empty')}
        />
      }
    >
      {(rows) => (
        <FlatList
          testID="connections-list"
          data={rows}
          keyExtractor={(r) => r.user_id}
          renderItem={({ item }) => (
            <Pressable
              testID={`connection-row-${item.handle}`}
              onPress={() => router.push(`/(app)/chats/${item.conversation_id}` as never)}
              className="flex-row items-center px-gutter py-3 border-b border-border active:bg-slate-100"
            >
              <AvatarCircle name={item.name ?? '?'} photoUrl={item.photo_url} size={48} />
              <View className="ml-3 flex-1">
                <Text className="font-display-bold text-display-sm text-navy">{item.name}</Text>
                <Text className="font-body text-body-sm text-muted">@{item.handle}</Text>
              </View>
            </Pressable>
          )}
        />
      )}
    </QueryState>
  );
}
