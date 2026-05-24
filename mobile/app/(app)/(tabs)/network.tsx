import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { TopBar } from '~/components/ui/TopBar';
import { ConnectionsList } from '~/features/connections/components/ConnectionsList';

export default function NetworkScreen() {
  const { t } = useTranslation();
  return (
    <View testID="network-screen" className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <TopBar title={t('nav.tabs.network')} />
        <ConnectionsList />
      </View>
    </View>
  );
}
