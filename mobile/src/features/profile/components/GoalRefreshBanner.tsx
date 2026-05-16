import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { Banner } from '~/components/ui/Banner';
import { Button } from '~/components/ui/Button';

const DAY_MS = 24 * 60 * 60 * 1000;

type Props = { goalUpdatedAt: string | null };

function ageDays(iso: string | null): number {
  if (!iso) return Infinity;
  return Math.floor((Date.now() - new Date(iso).getTime()) / DAY_MS);
}

export function GoalRefreshBanner({ goalUpdatedAt }: Props) {
  const age = ageDays(goalUpdatedAt);

  if (age < 28) return null;

  let variant: 'info' | 'warning' = 'info';
  let title = "How's your goal? Worth a refresh?";
  let body = 'People you match with rely on this. Keep it current.';

  if (age >= 49 && age < 56) {
    variant = 'warning';
    title = 'Your goal is starting to feel old';
    body = 'A short refresh will keep your matches relevant.';
  } else if (age >= 56) {
    variant = 'warning';
    title = 'Your goal hasn’t changed in 8+ weeks';
    body =
      'A short refresh keeps your matches relevant. We’ll email a reminder if it stays this old.';
  }

  return (
    <View testID="goal-refresh-banner" className="mx-3 my-2">
      <Banner variant={variant} title={title}>
        <View>
          <Text className="font-body text-[11px] mb-2">{body}</Text>
          <View className="self-start">
            <Button
              testID="goal-refresh-edit"
              size="small"
              variant={variant === 'warning' ? 'primary' : 'outline'}
              fullWidth={false}
              onPress={() => router.push('/(app)/profile/edit' as never)}
            >
              Update
            </Button>
          </View>
        </View>
      </Banner>
    </View>
  );
}
