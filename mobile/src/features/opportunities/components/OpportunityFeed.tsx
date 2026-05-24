import { useState } from 'react';
import { View, FlatList } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Briefcase } from 'lucide-react-native';
import { useOpportunities } from '~/features/opportunities/hooks/useOpportunities';
import { OpportunityCard } from './OpportunityCard';
import {
  OpportunityFilterBar,
  type OpportunityFilters,
} from './OpportunityFilterBar';
import { QueryState } from '~/components/ui/QueryState';
import { Button } from '~/components/ui/Button';
import { EmptyState } from '~/components/ui/EmptyState';
import { SkeletonOpportunityCard } from '~/components/ui/Skeleton';

/**
 * Top-level Opportunities feed. Owns the filter bar state and pipes it
 * straight into the query — toggling kinds / remote / search swaps the
 * cache entry rather than refetching the same key.
 */
export function OpportunityFeed() {
  const { t } = useTranslation();
  const [filters, setFilters] = useState<OpportunityFilters>({
    kinds: [],
    remoteOnly: false,
    search: '',
  });

  const query = useOpportunities({
    kinds: filters.kinds,
    remoteOnly: filters.remoteOnly,
    search: filters.search,
  });

  return (
    <View testID="opportunity-feed" className="flex-1 bg-surface">
      <OpportunityFilterBar value={filters} onChange={setFilters} />

      <QueryState
        query={query}
        isEmpty={(data) => data.length === 0}
        loadingFallback={
          <View className="pt-3">
            <SkeletonOpportunityCard count={4} />
          </View>
        }
        emptyFallback={
          <EmptyState
            testID="opportunity-feed-empty"
            icon={Briefcase}
            title={t('opportunities.feed.emptyTitle')}
            body={t('opportunities.feed.empty')}
            action={{
              label: t('opportunities.feed.newCta'),
              onPress: () => router.push('/(app)/opportunities/new'),
            }}
          />
        }
      >
        {(rows) => (
          <FlatList
            testID="opportunity-feed-list"
            data={rows}
            keyExtractor={(row) => row.id}
            renderItem={({ item }) => (
              <OpportunityCard
                opportunity={item}
                onPress={(id) =>
                  router.push({ pathname: '/(app)/opportunities/[id]', params: { id } })
                }
                onAuthorPress={(authorHandle) =>
                  router.push({ pathname: '/p/[handle]', params: { handle: authorHandle } })
                }
              />
            )}
            ListHeaderComponent={
              <View className="px-gutter py-3">
                <Button
                  testID="opportunity-feed-new-cta"
                  variant="primary"
                  onPress={() => router.push('/(app)/opportunities/new')}
                >
                  {t('opportunities.feed.newCta')}
                </Button>
              </View>
            }
            contentContainerStyle={{ paddingBottom: 24 }}
          />
        )}
      </QueryState>
    </View>
  );
}
