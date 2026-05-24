import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import {
  useProfileNudgeStore,
  isGoalNudgeDismissed,
  GOAL_NUDGE_TTL_DAYS,
} from '~/features/profile/store/profileNudgeStore';
import { useAuthSession } from '~/features/auth/SessionContext';
import { Banner } from '~/components/ui/Banner';
import { Button } from '~/components/ui/Button';

const DAY_MS = 24 * 60 * 60 * 1000;

type Props = { goalUpdatedAt: string | null };

function ageDays(iso: string | null): number {
  if (!iso) return Infinity;
  return Math.floor((Date.now() - new Date(iso).getTime()) / DAY_MS);
}

export function GoalRefreshBanner({ goalUpdatedAt }: Props) {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const dismissed = useProfileNudgeStore((s) => isGoalNudgeDismissed(s, userId));
  const dismissGoalNudge = useProfileNudgeStore((s) => s.dismissGoalNudge);

  const age = ageDays(goalUpdatedAt);

  if (age < 28 || dismissed) return null;

  let variant: 'info' | 'warning' = 'info';
  let title = t('profile.goalRefresh.titleInfo');
  let body = t('profile.goalRefresh.bodyInfo');

  if (age >= 49 && age < 56) {
    variant = 'warning';
    title = t('profile.goalRefresh.titleWarn');
    body = t('profile.goalRefresh.bodyWarn');
  } else if (age >= 56) {
    variant = 'warning';
    title = t('profile.goalRefresh.titleStale');
    body = t('profile.goalRefresh.bodyStale');
  }

  return (
    <View testID="goal-refresh-banner" className="mx-3 my-2">
      <Banner variant={variant} title={title}>
        <View>
          <Text className="font-body text-[11px] mb-2">{body}</Text>
          <View className="flex-row gap-2">
            <Button
              testID="goal-refresh-edit"
              size="small"
              variant={variant === 'warning' ? 'primary' : 'outline'}
              fullWidth={false}
              onPress={() => router.push('/(app)/profile/edit' as never)}
            >
              {t('profile.goalRefresh.update')}
            </Button>
            {userId ? (
              <Button
                testID="goal-refresh-snooze"
                size="small"
                variant="outline"
                fullWidth={false}
                onPress={() => dismissGoalNudge(userId)}
                accessibilityLabel={t('profile.goalRefresh.snoozeA11y', {
                  days: GOAL_NUDGE_TTL_DAYS,
                })}
              >
                {t('profile.goalRefresh.snooze', { days: GOAL_NUDGE_TTL_DAYS })}
              </Button>
            ) : null}
          </View>
        </View>
      </Banner>
    </View>
  );
}
