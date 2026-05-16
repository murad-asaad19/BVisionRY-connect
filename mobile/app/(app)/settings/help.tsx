import { ScrollView, View, Text } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { LegalSection } from '~/features/settings/components/LegalSection';
import { AppVersionSection } from '~/features/settings/components/AppVersionSection';

export default function HelpSubScreen() {
  const { t } = useTranslation();
  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.help') }} />
      <ScrollView className="flex-1">
        <View className="w-full max-w-2xl mx-auto p-4">
          <View className="bg-white rounded-xl border border-border p-4 mb-4">
            <Text className="font-display-bold text-[12px] text-body mb-1">
              {t('settings.contactTitle')}
            </Text>
            <Text className="font-body text-[11px] text-muted leading-relaxed">
              {t('settings.contactBody')}
            </Text>
          </View>
          <LegalSection />
          <AppVersionSection />
        </View>
      </ScrollView>
    </View>
  );
}
