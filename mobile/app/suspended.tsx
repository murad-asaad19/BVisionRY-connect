import { View, Text, Alert } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Button } from '~/components/ui/Button';
import { signOut } from '~/features/auth/services/auth.service';

export default function SuspendedScreen() {
  const { t } = useTranslation();
  return (
    <View testID="suspended-screen" className="flex-1 bg-surface px-6 pt-16 pb-8 items-center">
      <Stack.Screen options={{ headerShown: false }} />
      <View className="w-20 h-20 rounded-full bg-danger-bg border-2 border-danger-text items-center justify-center mb-4">
        <Text className="text-[28px] text-danger-text">!</Text>
      </View>
      <Text className="font-display-bold text-[20px] text-navy text-center mb-2">
        {t('suspended.title')}
      </Text>
      <Text className="font-body text-[12px] text-muted text-center mb-6 leading-snug max-w-md">
        {t('suspended.body')}
      </Text>
      <View className="w-full max-w-sm gap-3">
        <Button
          testID="suspended-appeal"
          variant="primary"
          onPress={() =>
            Alert.alert(t('suspended.submitAppeal'), t('suspended.contactBody'), [{ text: 'OK' }])
          }
        >
          {t('suspended.submitAppeal')}
        </Button>
        <Button
          testID="suspended-sign-out"
          variant="outline"
          onPress={() => signOut().catch(console.warn)}
        >
          {t('suspended.signOut')}
        </Button>
      </View>
    </View>
  );
}
