import { ScrollView, View, Text, Pressable, Linking } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { LegalSection } from '~/features/settings/components/LegalSection';
import { AppVersionSection } from '~/features/settings/components/AppVersionSection';

export default function HelpSubScreen() {
  const { t } = useTranslation();
  const supportEmail = t('settings.supportEmail');
  const openSupport = () => {
    Linking.openURL(`mailto:${supportEmail}`).catch((e) =>
      console.warn('[help] open mailto failed', e)
    );
  };
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
            <Pressable
              testID="help-support-email"
              accessibilityRole="link"
              accessibilityLabel={`mailto:${supportEmail}`}
              onPress={openSupport}
              className="mt-2"
            >
              <Text className="text-navy text-[12px] font-display-semibold underline">
                {supportEmail}
              </Text>
            </Pressable>
          </View>
          <LegalSection />
          <AppVersionSection />
        </View>
      </ScrollView>
    </View>
  );
}
