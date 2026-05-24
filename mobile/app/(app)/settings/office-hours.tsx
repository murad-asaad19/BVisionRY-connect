import { View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { OfficeHoursSettingsForm } from '~/features/office-hours/components/OfficeHoursSettingsForm';

export default function OfficeHoursSettingsScreen() {
  const { t } = useTranslation();
  return (
    <View testID="office-hours-settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('officeHours.settings.title') }} />
      <OfficeHoursSettingsForm />
    </View>
  );
}
