import { Redirect } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import { useNextRoute } from '~/features/auth/hooks/useNextRoute';

export default function Index() {
  const { state, href } = useNextRoute();

  if (state === 'loading') {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  return <Redirect href={href!} />;
}
