import { useTranslation } from 'react-i18next';
import { router } from 'expo-router';
import { MailOpen } from 'lucide-react-native';
import { EmptyState } from '~/components/ui/EmptyState';

type Props = { segment: 'received' | 'sent' };

export function EmptyInbox({ segment }: Props) {
  const { t } = useTranslation();
  return (
    <EmptyState
      testID="empty-inbox"
      icon={MailOpen}
      title={t('intros.empty.title')}
      body={segment === 'received' ? t('intros.empty.received') : t('intros.empty.sent')}
      action={{
        label: t('intros.empty.browse'),
        onPress: () => router.push('/(app)/(tabs)/home'),
      }}
    />
  );
}
