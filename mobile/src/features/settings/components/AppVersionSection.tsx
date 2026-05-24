import { View, Text } from 'react-native';
import * as Application from 'expo-application';
import { useTranslation } from 'react-i18next';

export function AppVersionSection() {
  const { t } = useTranslation();
  const version = Application.nativeApplicationVersion ?? '1.0.0';
  const build = Application.nativeBuildVersion ?? '';
  return (
    <View className="mt-6 mb-4">
      <Text className="font-display-semibold text-muted text-display-xs uppercase tracking-wide mb-2">
        {t('settings.about')}
      </Text>
      <Text testID="app-version" className="font-body text-muted text-body-md">
        {t('settings.version')} {version}
        {build ? ` (${build})` : ''}
      </Text>
    </View>
  );
}
