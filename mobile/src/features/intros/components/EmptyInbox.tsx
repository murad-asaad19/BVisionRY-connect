import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { router } from 'expo-router';
import { Button } from '~/components/ui/Button';

type Props = { segment: 'received' | 'sent' };

export function EmptyInbox({ segment }: Props) {
  const { t } = useTranslation();
  return (
    <View testID="empty-inbox" className="py-12 px-6 items-center">
      <View className="w-20 h-20 rounded-full bg-gold-pale items-center justify-center mb-4">
        <Text className="text-[28px]">✉</Text>
      </View>
      <Text className="font-display-bold text-[16px] text-navy mb-1">
        {t('intros.empty.title')}
      </Text>
      <Text className="font-body text-[12px] text-muted text-center mb-3 leading-snug">
        {segment === 'received' ? t('intros.empty.received') : t('intros.empty.sent')}
      </Text>
      <Button
        testID="empty-inbox-browse"
        variant="primary"
        fullWidth={false}
        onPress={() => router.push('/(app)/(tabs)/home')}
      >
        {t('intros.empty.browse')}
      </Button>
    </View>
  );
}
