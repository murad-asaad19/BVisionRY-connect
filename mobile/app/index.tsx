import { Redirect } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';

export default function Index() {
  const { session, loading: sessionLoading } = useAuthSession();
  const { data: profile, isLoading: profileLoading } = useCurrentUserProfile();

  if (sessionLoading || (session && profileLoading)) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#fff" />
      </View>
    );
  }

  if (!session) return <Redirect href="/(auth)/sign-in" />;
  if (profile && !profile.onboarded) return <Redirect href="/(onboarding)/goal" />;
  return <Redirect href="/(app)/(tabs)/home" />;
}
