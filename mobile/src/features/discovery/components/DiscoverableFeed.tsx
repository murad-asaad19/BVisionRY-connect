import { ReactElement } from 'react';
import { View, Text, FlatList, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import { useDiscoverableFeed } from '~/features/discovery/hooks/useDiscoverableFeed';
import { QueryState } from '~/components/ui/QueryState';
import { UserCard } from '~/components/ui/UserCard';

type Props = {
  ListHeaderComponent?: ReactElement | null;
};

export function DiscoverableFeed({ ListHeaderComponent }: Props) {
  const feed = useDiscoverableFeed();
  const { fetchNextPage, hasNextPage, isFetchingNextPage } = feed;

  return (
    <QueryState
      query={feed}
      isEmpty={(data) => data.pages.flatMap((p) => p.rows).length === 0}
      emptyFallback={
        <FlatList
          data={[]}
          renderItem={() => null}
          ListHeaderComponent={ListHeaderComponent}
          ListEmptyComponent={
            <View className="py-12 px-6 items-center">
              <Text className="text-muted text-center">No one to discover yet.</Text>
            </View>
          }
        />
      }
    >
      {(data) => {
        const rows = data.pages.flatMap((p) => p.rows);
        return (
          <FlatList
            testID="discoverable-feed"
            data={rows}
            keyExtractor={(item) => item.id}
            onEndReached={() => {
              if (hasNextPage && !isFetchingNextPage) {
                fetchNextPage();
              }
            }}
            onEndReachedThreshold={0.5}
            ListHeaderComponent={ListHeaderComponent}
            contentContainerStyle={{ paddingHorizontal: 12, gap: 8 }}
            ListFooterComponent={
              isFetchingNextPage ? (
                <View className="py-4 items-center">
                  <ActivityIndicator color="#fff" />
                </View>
              ) : null
            }
            renderItem={({ item }) => (
              <UserCard
                testID={`feed-card-${item.handle ?? 'unknown'}`}
                name={item.name ?? '?'}
                handle={item.handle ?? '?'}
                primaryRole={item.primary_role ?? ''}
                photoUrl={item.photo_url}
                headline={item.headline}
                location={
                  item.city || item.country
                    ? [item.city, item.country].filter(Boolean).join(', ')
                    : null
                }
                onPress={() => (item.handle ? router.push(`/p/${item.handle}`) : undefined)}
              />
            )}
          />
        );
      }}
    </QueryState>
  );
}
