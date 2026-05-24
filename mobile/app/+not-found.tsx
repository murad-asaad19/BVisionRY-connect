import { Stack, router } from 'expo-router';
import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Button } from '~/components/ui/Button';

export default function NotFoundScreen() {
  const { t } = useTranslation();
  return (
    <>
      <Stack.Screen options={{ title: t('notFound.title') }} />
      <View className="flex-1 items-center justify-center bg-surface px-6">
        <Text className="text-body text-2xl font-display-bold mb-2">{t('notFound.title')}</Text>
        <Text className="text-muted text-base text-center mb-6">{t('notFound.body')}</Text>
        <Button variant="primary" onPress={() => router.replace('/')}>
          {t('notFound.goHome')}
        </Button>
      </View>
    </>
  );
}
