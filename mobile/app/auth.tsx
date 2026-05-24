import { Redirect } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import { useAuthSession } from '~/features/auth/SessionContext';

export default function AuthCallback() {
  const { loading } = useAuthSession();

  if (loading) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  // Defer routing to the root (`app/index.tsx` + `useNextRoute`) which knows
  // about onboarding/suspension state — we just bounce out of this callback
  // screen once the deep-link has been consumed.
  return <Redirect href="/" />;
}
