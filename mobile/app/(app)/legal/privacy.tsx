import { ScrollView, Text, View } from 'react-native';
import { Stack } from 'expo-router';

export default function PrivacyPolicyScreen() {
  return (
    <View className="flex-1 bg-surface">
      <Stack.Screen options={{ title: 'Privacy Policy', headerShown: true }} />
      <ScrollView testID="privacy-screen" className="px-6 pt-4">
        <Text className="text-body text-xl font-semibold mb-3">Privacy Policy</Text>
        <Text className="text-muted mb-3">
          BVisionRY Connect collects and processes the data you provide when creating your profile
          (name, handle, role, goal, city, country, photo), the messages you send, intros you make,
          and meetings you propose. We use this data to deliver the core product: matching you with
          other professionals, delivering messages, and notifying you of events.
        </Text>
        <Text className="text-muted mb-3">
          We share data only with infrastructure vendors required to operate the service (Supabase
          for storage, Firebase for push notifications, Sentry for crash reports). We do not sell
          your data.
        </Text>
        <Text className="text-muted mb-3">
          You can export all your data at any time from Settings, and you can request full deletion
          at any time. Deletion is permanent and irreversible.
        </Text>
        <Text className="text-muted mb-8">Questions? Email privacy@bvisionry.example.</Text>
      </ScrollView>
    </View>
  );
}
