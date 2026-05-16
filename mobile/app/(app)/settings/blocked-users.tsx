import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { BlockedUsersList } from '~/features/privacy/components/BlockedUsersList';

export default function BlockedUsersSubScreen() {
  const { t } = useTranslation();
  return (
    <View testID="settings-screen" className="flex-1 bg-surface">
      <Stack.Screen options={{ title: t('settings.blockedUsers') }} />
      <ScrollView className="flex-1">
        <View className="w-full max-w-2xl mx-auto p-4">
          <BlockedUsersList />
        </View>
      </ScrollView>
    </View>
  );
}
