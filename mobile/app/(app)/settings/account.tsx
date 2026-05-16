import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { LanguageSection } from '~/features/settings/components/LanguageSection';
import { TelemetrySection } from '~/features/settings/components/TelemetrySection';
import { AccountSection } from '~/features/settings/components/AccountSection';

export default function AccountSubScreen() {
  const { t } = useTranslation();
  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.account') }} />
      <ScrollView className="flex-1">
        <View className="w-full max-w-2xl mx-auto p-4">
          <LanguageSection />
          <TelemetrySection />
          <AccountSection />
        </View>
      </ScrollView>
    </View>
  );
}
