import { Redirect, Stack } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import { useNextRoute } from '~/features/auth/hooks/useNextRoute';

export default function AuthLayout() {
  const { state, href } = useNextRoute();

  // Render a spinner during loading to avoid a flash of the auth form for
  // users who already have a session (e.g. just completed sign-up/sign-in).
  if (state === 'loading') {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  // Anything other than `unauthed` means the user has a destination outside
  // /(auth) — bounce them through the gate (suspended → /suspended,
  // unfinished onboarding → /(onboarding)/goal, otherwise → /(app)).
  if (state !== 'unauthed') {
    return <Redirect href={href!} />;
  }

  return <Stack screenOptions={{ headerShown: false }} />;
}
