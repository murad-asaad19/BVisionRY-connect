import { useEffect, useRef } from 'react';
import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useDailyMatches } from '~/features/discovery/hooks/useDailyMatches';
import { useMarkMatchViewed } from '~/features/discovery/hooks/useMarkMatchViewed';
import { QueryState } from '~/components/ui/QueryState';
import { UserCard } from '~/components/ui/UserCard';
import { SkeletonUserCard } from '~/components/ui/Skeleton';

/**
 * Daily matches render as a vertical stack (mockup C1). The top picks use the
 * featured UserCard variant. All rendered fields come from the widened
 * get_daily_matches RPC — no per-row profile fetch.
 */
export function DailyMatchesStrip() {
  const { t } = useTranslation();
  const dailyMatches = useDailyMatches();
  const markViewed = useMarkMatchViewed();

  // Session-scoped guard so the mark-viewed mutation fires at most once per
  // match id per app session. Combined with the optimistic cache patch in
  // useMarkMatchViewed.onSuccess, this prevents the effect-cache loop the
  // earlier implementation suffered from.
  const markedRef = useRef<Set<string>>(new Set());

  const matches = dailyMatches.data;

  useEffect(() => {
    if (!matches) return;
    matches.forEach((m) => {
      if (m.viewed_at) return;
      if (markedRef.current.has(m.id)) return;
      markedRef.current.add(m.id);
      markViewed.mutate(m.id);
    });
  }, [matches, markViewed]);

  return (
    <QueryState
      query={dailyMatches}
      loadingFallback={
        <View className="pt-1 pb-2">
          <SkeletonUserCard count={3} />
        </View>
      }
      isEmpty={(data) => data.length === 0}
      emptyFallback={
        <View className="h-32 items-center justify-center px-gutter">
          <Text className="font-body text-body-md text-muted text-center">{t('discovery.emptyPicks')}</Text>
        </View>
      }
    >
      {(rows) => (
        <View testID="daily-matches-strip" className="px-3 gap-2 pb-2">
          {rows.map((row, index) => {
            const location =
              row.city || row.country
                ? [row.city, row.country].filter(Boolean).join(', ')
                : null;
            return (
              <UserCard
                key={row.id}
                testID={`match-card-${row.handle ?? 'unknown'}`}
                variant={index < 2 ? 'featured' : 'default'}
                name={row.name ?? '?'}
                handle={row.handle ?? '?'}
                primaryRole={row.primary_role ?? ''}
                photoUrl={row.photo_url}
                headline={row.headline}
                reason={row.match_reason}
                location={location}
                onPress={() => (row.handle ? router.push(`/p/${row.handle}`) : undefined)}
              />
            );
          })}
        </View>
      )}
    </QueryState>
  );
}
