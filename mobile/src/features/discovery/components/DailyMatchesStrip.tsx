import { useEffect } from 'react';
import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { useQueries } from '@tanstack/react-query';
import { useDailyMatches } from '~/features/discovery/hooks/useDailyMatches';
import { useMarkMatchViewed } from '~/features/discovery/hooks/useMarkMatchViewed';
import { QueryState } from '~/components/ui/QueryState';
import { UserCard } from '~/components/ui/UserCard';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

type ProfileRow = Database['public']['Tables']['profiles']['Row'];

/**
 * Daily matches now render as a vertical stack (mockup C1) instead of a
 * horizontal strip. The top picks render with the featured UserCard variant.
 */
export function DailyMatchesStrip() {
  const dailyMatches = useDailyMatches();
  const markViewed = useMarkMatchViewed();

  const matches = dailyMatches.data;

  const pickQueries = useQueries({
    queries: (matches ?? []).map((m) => ({
      queryKey: ['profile-by-id', m.pick_user_id],
      queryFn: async (): Promise<ProfileRow | null> => {
        const { data, error } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', m.pick_user_id)
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

  useEffect(() => {
    matches?.forEach((m) => {
      if (!m.viewed_at) markViewed.mutate(m.id);
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [matches]);

  return (
    <QueryState
      query={dailyMatches}
      isEmpty={(data) => data.length === 0}
      emptyFallback={
        <View className="h-32 items-center justify-center px-6">
          <Text className="text-muted text-center">
            No picks yet — invite friends to populate your matches.
          </Text>
        </View>
      }
    >
      {(rows) => {
        const items = rows
          .map((m, i) => {
            const pick = pickQueries[i]?.data;
            if (!pick) return null;
            return { match: m, pick };
          })
          .filter((x): x is { match: (typeof rows)[0]; pick: ProfileRow } => x !== null);

        return (
          <View testID="daily-matches-strip" className="px-3 gap-2 pb-2">
            {items.map((item, index) => (
              <UserCard
                key={item.match.id}
                testID={`match-card-${item.pick.handle ?? 'unknown'}`}
                variant={index < 2 ? 'featured' : 'default'}
                name={item.pick.name ?? '?'}
                handle={item.pick.handle ?? '?'}
                primaryRole={item.pick.primary_role ?? ''}
                photoUrl={item.pick.photo_url}
                headline={item.pick.headline}
                reason={item.match.match_reason}
                location={
                  item.pick.city || item.pick.country
                    ? [item.pick.city, item.pick.country].filter(Boolean).join(', ')
                    : null
                }
                onPress={() =>
                  item.pick.handle ? router.push(`/p/${item.pick.handle}`) : undefined
                }
              />
            ))}
          </View>
        );
      }}
    </QueryState>
  );
}
