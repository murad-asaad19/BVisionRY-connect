import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Button } from '~/components/ui/Button';

export function LegalSection() {
  const { t } = useTranslation();
  return (
    <View className="mt-6 mb-12">
      <Text className="font-display-semibold text-muted text-display-xs uppercase tracking-wide mb-2">
        {t('settings.legal')}
      </Text>
      <View className="mb-2">
        <Button
          testID="legal-privacy"
          variant="outline"
          onPress={() => router.push('/(app)/legal/privacy' as never)}
        >
          {t('settings.privacyPolicy')}
        </Button>
      </View>
      <Button
        testID="legal-terms"
        variant="outline"
        onPress={() => router.push('/(app)/legal/terms' as never)}
      >
        {t('settings.termsOfService')}
      </Button>
    </View>
  );
}
