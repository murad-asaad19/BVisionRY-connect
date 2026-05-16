import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { ConnectionsList } from '~/features/connections/components/ConnectionsList';

export default function NetworkScreen() {
  const { t } = useTranslation();
  return (
    <View testID="network-screen" className="flex-1 bg-surface">
      <View className="flex-1 w-full max-w-2xl mx-auto">
        <View className="px-6 pt-16 pb-4">
          <Text className="text-body text-2xl font-semibold">{t('network.title')}</Text>
        </View>
        <ConnectionsList />
      </View>
    </View>
  );
}
