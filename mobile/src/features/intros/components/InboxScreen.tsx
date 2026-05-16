import { useMemo, useState } from 'react';
import { View, FlatList, ActivityIndicator } from 'react-native';
import { router } from 'expo-router';
import { useQueries } from '@tanstack/react-query';
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
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';
import type { IntroRow } from '~/features/intros/services/intros.service';

type ProfileLite = Pick<
  Database['public']['Tables']['profiles']['Row'],
  'id' | 'name' | 'handle' | 'photo_url'
>;

type Segment = 'received' | 'sent';

const DAILY_INBOUND_CAP = 20;

function countToday(rows: IntroRow[]): number {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const cutoff = today.getTime();
  return rows.filter((r) => new Date(r.created_at).getTime() >= cutoff).length;
}

export function InboxScreen() {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const [segment, setSegment] = useState<Segment>('received');

  const inboxQuery = useInbox();
  const sentQuery = useSent();
  const active = segment === 'received' ? inboxQuery : sentQuery;
  const intros: IntroRow[] = active.data?.pages.flatMap((p) => p.rows) ?? [];

  const counterpartIds = useMemo(() => {
    return intros
      .map((i) => (segment === 'received' ? i.sender_id : i.recipient_id))
      .filter((x): x is string => !!x);
  }, [intros, segment]);

  const counterpartQueries = useQueries({
    queries: counterpartIds.map((id) => ({
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

  const counterpartById = new Map<string, ProfileLite>();
  counterpartQueries.forEach((q, i) => {
    const id = counterpartIds[i];
    if (id && q.data) counterpartById.set(id, q.data);
  });

  void session;

  const receivedToday =
    segment === 'received' ? countToday(inboxQuery.data?.pages.flatMap((p) => p.rows) ?? []) : 0;
  const overCap = segment === 'received' && receivedToday >= DAILY_INBOUND_CAP;

  return (
    <View className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <TopBar title={t('intros.inboxTitle')} />
        {overCap ? (
          <View testID="inbox-cap-banner" className="mx-3 mt-2">
            <Banner variant="warning" title="Daily limit reached">
              Incoming intros above {DAILY_INBOUND_CAP} are queued for tomorrow.
            </Banner>
          </View>
        ) : null}
        <InboxTabs active={segment} onChange={setSegment} />

        <QueryState
          query={active}
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
                      <ActivityIndicator color="#0f3460" />
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
