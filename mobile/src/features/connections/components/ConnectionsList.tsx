import { View, Text, Pressable, FlatList } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useConnections } from '~/features/connections/hooks/useConnections';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { QueryState } from '~/components/ui/QueryState';

export function ConnectionsList() {
  const { t } = useTranslation();
  const q = useConnections();
  return (
    <QueryState
      query={q}
      isEmpty={(rows) => rows.length === 0}
      emptyFallback={
        <View className="py-12 px-6 items-center" testID="connections-empty">
          <Text className="text-muted text-center">{t('connections.empty')}</Text>
        </View>
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
              className="flex-row items-center px-4 py-3 border-b border-border"
            >
              <AvatarCircle name={item.name ?? '?'} photoUrl={item.photo_url} size={48} />
              <View className="ml-3 flex-1">
                <Text className="text-body font-semibold">{item.name}</Text>
                <Text className="text-muted text-sm">@{item.handle}</Text>
              </View>
            </Pressable>
          )}
        />
      )}
    </QueryState>
  );
}
