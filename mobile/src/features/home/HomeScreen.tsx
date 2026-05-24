import { useCallback, useState } from 'react';
import { View, Text, RefreshControl } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useQueryClient } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { useDailyMatches } from '~/features/discovery/hooks/useDailyMatches';
import { useDiscoverableFeed } from '~/features/discovery/hooks/useDiscoverableFeed';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { TopBar } from '~/components/ui/TopBar';
import { DailyMatchesStrip } from '~/features/discovery/components/DailyMatchesStrip';
import { DiscoverableFeed } from '~/features/discovery/components/DiscoverableFeed';
import { FeedFilterBar } from '~/features/discovery/components/FeedFilterBar';
import { ThinPoolBanner } from '~/features/discovery/components/ThinPoolBanner';
import { GoalRefreshBanner } from '~/features/profile/components/GoalRefreshBanner';
import { PhotoNudgeBanner } from '~/features/profile/components/PhotoNudgeBanner';

export function HomeScreen() {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const { data: profile } = useCurrentUserProfile();
  const dailyMatches = useDailyMatches();
  const feed = useDiscoverableFeed();
  const qc = useQueryClient();

  const [refreshing, setRefreshing] = useState(false);

  const matchCount = dailyMatches.data?.length ?? 0;
  const thinPool = !dailyMatches.isLoading && matchCount > 0 && matchCount < 3;

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      await Promise.all([
        dailyMatches.refetch(),
        feed.refetch(),
        qc.invalidateQueries({ queryKey: ['profile'] }),
      ]);
    } finally {
      setRefreshing(false);
    }
  }, [dailyMatches, feed, qc]);

  return (
    <View className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <DiscoverableFeed
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#fff" />
          }
          ListHeaderComponent={
            <View>
              <TopBar
                title={t('home.title')}
                titleTestID="home-title"
                actions={[
                  {
                    testID: 'home-avatar',
                    icon: (
                      <AvatarCircle
                        name={profile?.name ?? session?.user.email ?? '?'}
                        photoUrl={profile?.photo_url ?? null}
                        size={38}
                      />
                    ),
                    onPress: () => router.push('/(app)/profile'),
                    accessibilityLabel: 'Open profile',
                  },
                ]}
              />
              <GoalRefreshBanner goalUpdatedAt={profile?.goal_updated_at ?? null} />
              <PhotoNudgeBanner photoUrl={profile?.photo_url ?? null} />
              {thinPool ? <ThinPoolBanner count={matchCount} /> : null}
              <Text
                className="font-display-bold text-[12px] text-muted uppercase tracking-wide px-4 pt-3 pb-1"
                testID="home-section-picks"
              >
                {t('home.picks')}
              </Text>
              <DailyMatchesStrip />
              <Text
                className="font-display-bold text-[12px] text-muted uppercase tracking-wide px-4 pt-3 pb-1"
                testID="home-section-discover"
              >
                {t('home.discover')}
              </Text>
              <FeedFilterBar />
            </View>
          }
        />
      </View>
    </View>
  );
}
