import { useState } from 'react';
import { View, Text, FlatList } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useOpportunities } from '~/features/opportunities/hooks/useOpportunities';
import { OpportunityCard } from './OpportunityCard';
import {
  OpportunityFilterBar,
  type OpportunityFilters,
} from './OpportunityFilterBar';
import { QueryState } from '~/components/ui/QueryState';
import { Button } from '~/components/ui/Button';

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
        emptyFallback={
          <View className="flex-1 items-center justify-center px-6 py-10">
            <Text className="font-body text-[13px] text-muted text-center mb-3">
              {t('opportunities.feed.empty')}
            </Text>
            <View>
              <Button
                testID="opportunity-feed-new-cta-empty"
                variant="primary"
                fullWidth={false}
                onPress={() => router.push('/(app)/opportunities/new')}
              >
                {t('opportunities.feed.newCta')}
              </Button>
            </View>
          </View>
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
                onAuthorPress={(authorId) =>
                  router.push({ pathname: '/(app)/p/[handle]', params: { handle: authorId } })
                }
              />
            )}
            ListHeaderComponent={
              <View className="px-3 py-3">
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
