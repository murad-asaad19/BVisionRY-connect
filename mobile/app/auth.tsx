import { Redirect } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import { useAuthSession } from '~/features/auth/SessionContext';

export default function AuthCallback() {
  const { session, loading } = useAuthSession();

  if (loading) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  return <Redirect href={session ? '/(app)/(tabs)/home' : '/(auth)/sign-in'} />;
}
