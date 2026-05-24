import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import {
  useProfileNudgeStore,
  isPhotoNudgeDismissed,
} from '~/features/profile/store/profileNudgeStore';
import { useAuthSession } from '~/features/auth/SessionContext';
import { Banner } from '~/components/ui/Banner';
import { Button } from '~/components/ui/Button';

type Props = {
  photoUrl: string | null | undefined;
  /**
   * When false, the banner is suppressed regardless of dismiss state.
   * Used by `ProfileView` to hide this nudge when the broader profile-
   * completeness banner already lists "photo" as missing.
   */
  visible?: boolean;
};

export function PhotoNudgeBanner({ photoUrl, visible = true }: Props) {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const dismissed = useProfileNudgeStore((s) => isPhotoNudgeDismissed(s, userId));
  const dismissPhotoNudge = useProfileNudgeStore((s) => s.dismissPhotoNudge);

  if (!visible || photoUrl || dismissed || !userId) return null;

  return (
    <View className="mx-4 mb-2">
      <Banner testID="photo-nudge-banner" variant="info" title={t('profile.photoNudgeTitle')}>
        <View className="flex-row items-center justify-between gap-2">
          <Text className="text-info-text text-[11px] font-body flex-1">
            {t('profile.photoNudgeBody')}
          </Text>
          <Button
            testID="photo-nudge-add"
            variant="primary"
            size="small"
            fullWidth={false}
            onPress={() => router.push('/(app)/profile/edit' as never)}
            accessibilityLabel={t('profile.photoNudgeAction')}
          >
            {t('profile.photoNudgeAction')}
          </Button>
          <Pressable
            testID="photo-nudge-dismiss"
            onPress={() => dismissPhotoNudge(userId)}
            className="px-2 py-2"
            accessibilityRole="button"
            accessibilityLabel={t('profile.photoNudgeDismiss')}
          >
            <Text className="text-muted font-display-bold">X</Text>
          </Pressable>
        </View>
      </Banner>
    </View>
  );
}
