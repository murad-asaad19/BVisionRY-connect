import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { PrivacyTogglesSection } from '~/features/privacy/components/PrivacyTogglesSection';

export default function PrivacySubScreen() {
  const { t } = useTranslation();
  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.privacy') }} />
      <ScrollView className="flex-1">
        <View className="w-full max-w-2xl mx-auto p-card-lg">
          <PrivacyTogglesSection />
        </View>
      </ScrollView>
    </View>
  );
}
