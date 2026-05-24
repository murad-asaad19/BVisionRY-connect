import { Stack } from 'expo-router';
import { ProfileView } from '~/features/profile/components/ProfileView';

export default function ProfileRoute() {
  // ProfileView renders its own TopBar (with Edit/Share actions); the Stack
  // header would duplicate the chrome and clash with the gradient hero.
  return (
    <>
      <Stack.Screen options={{ headerShown: false }} />
      <ProfileView />
    </>
  );
}
