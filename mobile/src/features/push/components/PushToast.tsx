import { useState } from 'react';
import { Text, View, Pressable } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useForegroundMessages } from '~/features/push/hooks/useForegroundMessages';

export function PushToast() {
  const toast = useForegroundMessages();
  const { t } = useTranslation();
  // Local dismissed flag lets the user close the toast before the 5s auto-clear.
  // Reset whenever a new toast arrives by keying on title+body.
  const [dismissedKey, setDismissedKey] = useState<string | null>(null);

  if (!toast) return null;

  const key = `${toast.title}::${toast.body}`;
  if (dismissedKey === key) return null;

  const dismiss = () => setDismissedKey(key);

  return (
    <SafeAreaView
      edges={['top']}
      pointerEvents="box-none"
      className="absolute top-0 left-0 right-0 z-50"
    >
      <View className="mx-4 mt-2 bg-white border border-border rounded-xl flex-row items-start">
        <Pressable
          testID="push-toast"
          onPress={() => {
            if (toast.url) router.push(toast.url as never);
            dismiss();
          }}
          accessibilityRole="button"
          accessibilityLabel={t('push.toastOpenA11y')}
          className="flex-1 p-3"
        >
          <Text testID="push-toast-title" className="text-body font-semibold" numberOfLines={1}>
            {toast.title}
          </Text>
          {toast.body ? (
            <Text testID="push-toast-body" className="text-muted text-sm" numberOfLines={2}>
              {toast.body}
            </Text>
          ) : null}
        </Pressable>
        <Pressable
          testID="push-toast-dismiss"
          onPress={dismiss}
          accessibilityRole="button"
          accessibilityLabel={t('push.toastDismissA11y')}
          hitSlop={8}
          className="p-3"
        >
          <Text className="text-muted text-lg leading-none">{'✕'}</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}
