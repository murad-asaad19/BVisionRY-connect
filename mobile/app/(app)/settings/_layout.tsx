import { Stack } from 'expo-router';

export default function SettingsSubLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: { backgroundColor: '#ffffff' },
        headerTintColor: '#0f3460',
        headerTitleStyle: { fontFamily: 'Dosis_700Bold' },
      }}
    />
  );
}
