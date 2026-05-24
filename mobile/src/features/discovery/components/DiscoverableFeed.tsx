import { ReactElement } from 'react';
import { View, Text, FlatList, ActivityIndicator, RefreshControl } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useDiscoverableFeed } from '~/features/discovery/hooks/useDiscoverableFeed';
import { QueryState } from '~/components/ui/QueryState';
import { UserCard } from '~/components/ui/UserCard';
import { WarmIntroSuggestionsStrip } from '~/features/intros/components/WarmIntroSuggestionsStrip';

type Props = {
  ListHeaderComponent?: ReactElement | null;
  /**
   * Optional pre-built RefreshControl. Pass when the parent screen needs to
   * orchestrate pull-to-refresh across multiple queries (e.g. HomeScreen
   * refreshing both daily matches and the feed). When omitted, the feed
   * manages its own refresh wired to `feed.refetch`.
   */
  refreshControl?: ReactElement;
};

export function DiscoverableFeed({ ListHeaderComponent, refreshControl }: Props) {
  const { t } = useTranslation();
  const feed = useDiscoverableFeed();
  const { fetchNextPage, hasNextPage, isFetchingNextPage, isRefetching, refetch } = feed;

  const effectiveRefreshControl =
    refreshControl ??
    (<RefreshControl refreshing={isRefetching} onRefresh={() => refetch()} tintColor="#fff" />);

  // Compose the warm-intro suggestions strip into the FlatList header so it
  // sits above the feed cards and scrolls with them. The strip returns null
  // when there are no suggestions, so we don't pay layout cost for new
  // accounts. Parent-provided ListHeaderComponent (TopBar etc.) still
  // renders above the strip.
  const composedHeader = (
    <View>
      {ListHeaderComponent}
      <WarmIntroSuggestionsStrip />
    </View>
  );

  return (
    <QueryState
      query={feed}
      isEmpty={(data) => data.pages.flatMap((p) => p.rows).length === 0}
      emptyFallback={
        <FlatList
          data={[]}
          renderItem={() => null}
          ListHeaderComponent={ListHeaderComponent}
          refreshControl={effectiveRefreshControl}
          ListEmptyComponent={
            <View className="py-12 px-6 items-center">
              <Text className="text-muted text-center">{t('discovery.emptyFeed')}</Text>
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
            ListHeaderComponent={composedHeader}
            refreshControl={effectiveRefreshControl}
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
