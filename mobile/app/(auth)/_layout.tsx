import { Redirect, Stack } from 'expo-router';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';

export default function AuthLayout() {
  const { session, loading: sessionLoading } = useAuthSession();
  const { data: profile, isLoading: profileLoading } = useCurrentUserProfile();

  // If a session already exists when the user lands on an auth screen (e.g.
  // they just completed password sign-up or sign-in), bounce them straight
  // through the auth gate so they don't sit on /sign-up after the request
  // succeeds. Wait until both session + profile have resolved to avoid a
  // flash of /sign-in for unauthenticated users.
  if (!sessionLoading && session && !profileLoading) {
    if (profile && !profile.onboarded) {
      return <Redirect href="/(onboarding)/goal" />;
    }
    return <Redirect href="/(app)/(tabs)/home" />;
  }

  return <Stack screenOptions={{ headerShown: false }} />;
}
