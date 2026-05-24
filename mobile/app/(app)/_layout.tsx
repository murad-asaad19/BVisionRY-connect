import { Redirect, Stack } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import { useNextRoute } from '~/features/auth/hooks/useNextRoute';

export default function AppLayout() {
  const { state, href } = useNextRoute();

  if (state === 'loading') {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  if (state !== 'app') {
    return <Redirect href={href!} />;
  }

  return <Stack screenOptions={{ headerShown: false }} />;
}
