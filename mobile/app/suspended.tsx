import { View, Text } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { AlertTriangle } from 'lucide-react-native';
import { Button } from '~/components/ui/Button';
import { useConfirm } from '~/components/ui/ConfirmDialog';
import { signOut } from '~/features/auth/services/auth.service';
import { colors } from '~/theme/colors';

export default function SuspendedScreen() {
  const { t } = useTranslation();
  const confirm = useConfirm();
  return (
    <View testID="suspended-screen" className="flex-1 bg-surface px-gutter pt-16 pb-8 items-center">
      <Stack.Screen options={{ headerShown: false }} />
      <View className="w-20 h-20 rounded-full bg-danger-bg border-2 border-danger-text items-center justify-center mb-4">
        <AlertTriangle size={32} color={colors.danger} />
      </View>
      <Text className="font-display-bold text-display-lg text-navy text-center mb-2">
        {t('suspended.title')}
      </Text>
      <Text className="font-body text-body-md text-muted text-center mb-6 leading-snug max-w-md">
        {t('suspended.body')}
      </Text>
      <View className="w-full max-w-sm gap-3">
        <Button
          testID="suspended-appeal"
          variant="primary"
          onPress={() =>
            confirm({
              title: t('suspended.submitAppeal'),
              body: t('suspended.contactBody'),
              confirmLabel: t('common.ok'),
            })
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
