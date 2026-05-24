import { useMemo, useState } from 'react';
import { View, FlatList, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { useInbox } from '~/features/intros/hooks/useInbox';
import { useSent } from '~/features/intros/hooks/useSent';
import { useAuthSession } from '~/features/auth/SessionContext';
import { IntroListRow } from './IntroListRow';
import { InboxTabs } from './InboxTabs';
import { EmptyInbox } from './EmptyInbox';
import { QueryState } from '~/components/ui/QueryState';
import { TopBar } from '~/components/ui/TopBar';
import { Banner } from '~/components/ui/Banner';
import { SkeletonIntroRow } from '~/components/ui/Skeleton';
import { supabase } from '~/lib/supabase/client';
import { fetchIntrosTodayCount } from '~/features/intros/services/intros.service';
import { colors } from '~/theme/colors';
import type { Database } from '~/lib/supabase/types.gen';
import type { IntroRow } from '~/features/intros/services/intros.service';

type ProfileLite = Pick<
  Database['public']['Tables']['profiles']['Row'],
  'id' | 'name' | 'handle' | 'photo_url'
>;

type Segment = 'received' | 'sent';

const DAILY_INBOUND_CAP = 20;

export function InboxScreen() {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const [segment, setSegment] = useState<Segment>('received');

  const inboxQuery = useInbox();
  const sentQuery = useSent();
  const active = segment === 'received' ? inboxQuery : sentQuery;
  const intros: IntroRow[] = active.data?.pages.flatMap((p) => p.rows) ?? [];

  // Stable, sorted key so two queries with the same membership share a cache entry
  // regardless of pagination ordering.
  const counterpartIds = useMemo(() => {
    const set = new Set<string>();
    for (const i of intros) {
      const id = segment === 'received' ? i.sender_id : i.recipient_id;
      if (id) set.add(id);
    }
    return Array.from(set).sort();
  }, [intros, segment]);

  // Single batched lookup — replaces N+1 useQueries fan-out.
  const counterpartsQuery = useQuery({
    queryKey: ['profiles', 'lite-batch', counterpartIds],
    enabled: counterpartIds.length > 0,
    staleTime: 60_000,
    queryFn: async (): Promise<Map<string, ProfileLite>> => {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, handle, photo_url')
        .in('id', counterpartIds);
      if (error) throw new Error(error.message);
      const map = new Map<string, ProfileLite>();
      for (const row of data ?? []) map.set(row.id, row as ProfileLite);
      return map;
    },
  });
  const counterpartById = counterpartsQuery.data ?? new Map<string, ProfileLite>();

  // Server-truth daily-cap probe; only meaningful for the received tab.
  const todayCountQuery = useQuery({
    queryKey: ['intros', 'today-count', session?.user.id],
    enabled: !!session?.user.id && segment === 'received',
    staleTime: 60_000,
    queryFn: fetchIntrosTodayCount,
  });
  const overCap =
    segment === 'received' && (todayCountQuery.data ?? 0) >= DAILY_INBOUND_CAP;

  return (
    <View className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <TopBar title={t('intros.inboxTitle')} />
        {overCap ? (
          <View testID="inbox-cap-banner" className="mx-gutter mt-2">
            <Banner variant="warning" title={t('intros.banner.dailyCapTitle')}>
              {t('intros.banner.dailyCapBody', { cap: DAILY_INBOUND_CAP })}
            </Banner>
          </View>
        ) : null}
        <InboxTabs active={segment} onChange={setSegment} />

        <QueryState
          query={active}
          loadingFallback={
            <View className="pt-3">
              <SkeletonIntroRow count={5} />
            </View>
          }
          isEmpty={(data) => data.pages.flatMap((p) => p.rows).length === 0}
          emptyFallback={<EmptyInbox segment={segment} />}
        >
          {(data) => {
            const rows = data.pages.flatMap((p) => p.rows);
            return (
              <FlatList
                testID={`inbox-list-${segment}`}
                data={rows}
                keyExtractor={(r) => r.id}
                onEndReached={() => {
                  if (active.hasNextPage && !active.isFetchingNextPage) {
                    active.fetchNextPage();
                  }
                }}
                onEndReachedThreshold={0.5}
                ListFooterComponent={
                  active.isFetchingNextPage ? (
                    <View className="py-4 items-center">
                      <ActivityIndicator color={colors.navy} />
                    </View>
                  ) : null
                }
                renderItem={({ item }) => {
                  const counterpartId = segment === 'received' ? item.sender_id : item.recipient_id;
                  const counterpart = counterpartId
                    ? (counterpartById.get(counterpartId) ?? null)
                    : null;
                  return (
                    <IntroListRow
                      intro={item}
                      counterpart={counterpart}
                      audience={segment === 'received' ? 'recipient' : 'sender'}
                      onPress={() =>
                        router.push({ pathname: '/(app)/intros/[id]', params: { id: item.id } })
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
