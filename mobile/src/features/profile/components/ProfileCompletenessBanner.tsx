import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import type { Database } from '~/lib/supabase/types.gen';
import { Banner } from '~/components/ui/Banner';
import { Button } from '~/components/ui/Button';

type ProfileRow = Database['public']['Tables']['profiles']['Row'];

export function ProfileCompletenessBanner({ profile }: { profile: ProfileRow }) {
  const { t } = useTranslation();
  const missing: string[] = [];
  if (!profile.photo_url) missing.push(t('profile.missingPhoto'));
  if (!profile.headline) missing.push(t('profile.missingHeadline'));
  if (!profile.bio) missing.push(t('profile.missingBio'));
  if (missing.length === 0) return null;

  const percent = Math.round(((3 - missing.length) / 3) * 100);

  return (
    <View className="mb-4">
      <Banner
        testID="profile-completeness"
        variant="info"
        title={t('profile.completenessTitle', { percent })}
      >
        <View className="flex-row items-center justify-between gap-3">
          <Text className="text-info-text text-[11px] font-body flex-1">
            {t('profile.completenessMissing', { fields: missing.join(', ') })}
          </Text>
          <Button
            testID="profile-completeness-edit"
            variant="primary"
            size="small"
            fullWidth={false}
            onPress={() => router.push('/(app)/profile/edit' as never)}
            accessibilityLabel={t('profile.completenessAction')}
          >
            {t('profile.completenessAction')}
          </Button>
        </View>
      </Banner>
    </View>
  );
}
