import { Pressable, Text } from 'react-native';
import { Stack, router } from 'expo-router';
import { ProfileView } from '~/features/profile/components/ProfileView';

export default function ProfileRoute() {
  return (
    <>
      <Stack.Screen
        options={{
          title: 'Profile',
          headerShown: true,
          headerRight: () => (
            <Pressable
              testID="profile-settings"
              onPress={() => router.push('/(app)/settings' as never)}
              accessibilityRole="button"
              accessibilityLabel="Open settings"
              className="px-2 py-1"
            >
              <Text className="text-body text-base">âš™</Text>
            </Pressable>
          ),
        }}
      />
      <ProfileView />
    </>
  );
}
