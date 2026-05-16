import { ScrollView, Text, View } from 'react-native';
import { Stack } from 'expo-router';

export default function TermsOfServiceScreen() {
  return (
    <View className="flex-1 bg-surface">
      <Stack.Screen options={{ title: 'Terms of Service', headerShown: true }} />
      <ScrollView testID="terms-screen" className="px-6 pt-4">
        <Text className="text-body text-xl font-semibold mb-3">Terms of Service</Text>
        <Text className="text-muted mb-3">
          By using BVisionRY Connect, you agree to use the service for lawful professional
          networking purposes. You will not harass, impersonate, spam, or share inappropriate
          content. We may suspend or remove accounts that violate these rules.
        </Text>
        <Text className="text-muted mb-3">
          The service is provided as-is, without warranty. We may change features at any time. We
          are not liable for any damages arising from use of the service.
        </Text>
        <Text className="text-muted mb-8">Questions? Email legal@bvisionry.example.</Text>
      </ScrollView>
    </View>
  );
}
