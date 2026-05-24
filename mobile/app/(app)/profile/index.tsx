import { Pressable, Text } from 'react-native';
import { Stack, router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { ProfileView } from '~/features/profile/components/ProfileView';

export default function ProfileRoute() {
  const { t } = useTranslation();
  return (
    <>
      <Stack.Screen
        options={{
          title: t('settings.profile'),
          headerShown: true,
          headerRight: () => (
            <Pressable
              testID="profile-settings"
              onPress={() => router.push('/(app)/settings' as never)}
              accessibilityRole="button"
              accessibilityLabel={t('profile.settingsA11y')}
              className="px-2 py-1"
            >
              <Text className="text-body text-base">⚙</Text>
            </Pressable>
          ),
        }}
      />
      <ProfileView />
    </>
  );
}
