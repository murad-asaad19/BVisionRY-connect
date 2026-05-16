import { View, Text, Alert } from 'react-native';
import { Stack } from 'expo-router';
import { Button } from '~/components/ui/Button';
import { signOut } from '~/features/auth/services/auth.service';

export default function SuspendedScreen() {
  return (
    <View testID="suspended-screen" className="flex-1 bg-surface px-6 pt-16 pb-8 items-center">
      <Stack.Screen options={{ headerShown: false }} />
      <View className="w-20 h-20 rounded-full bg-danger-bg border-2 border-danger-text items-center justify-center mb-4">
        <Text className="text-[28px] text-danger-text">!</Text>
      </View>
      <Text className="font-display-bold text-[20px] text-navy text-center mb-2">
        Your account is under review
      </Text>
      <Text className="font-body text-[12px] text-muted text-center mb-6 leading-snug max-w-md">
        We&apos;re reviewing recent activity on your account. Most reviews complete within 48 hours.
        Until then, sign-in and discovery are paused.
      </Text>
      <View className="w-full max-w-sm gap-3">
        <Button
          testID="suspended-appeal"
          variant="primary"
          onPress={() =>
            Alert.alert(
              'Submit appeal',
              "We'll email you the appeal form. Please check your inbox in a few minutes.",
              [{ text: 'OK' }]
            )
          }
        >
          Submit appeal
        </Button>
        <Button
          testID="suspended-sign-out"
          variant="outline"
          onPress={() => signOut().catch(console.warn)}
        >
          Sign out
        </Button>
      </View>
    </View>
  );
}
