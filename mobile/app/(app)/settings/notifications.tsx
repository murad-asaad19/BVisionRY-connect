import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { NotificationPrefsSection } from '~/features/settings/components/NotificationPrefsSection';

export default function NotificationsSubScreen() {
  const { t } = useTranslation();
  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.notifications') }} />
      <ScrollView className="flex-1">
        <View className="w-full max-w-2xl mx-auto">
          <NotificationPrefsSection />
        </View>
      </ScrollView>
    </View>
  );
}
