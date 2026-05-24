import { Stack } from 'expo-router';
import { colors } from '~/theme/colors';

export default function SettingsSubLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: { backgroundColor: colors.white },
        headerTintColor: colors.navy,
        headerTitleStyle: { fontFamily: 'Dosis_700Bold' },
      }}
    />
  );
}
