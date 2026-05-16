import { Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useForegroundMessages } from '~/features/push/hooks/useForegroundMessages';

export function PushToast() {
  const toast = useForegroundMessages();
  if (!toast) return null;
  return (
    <Pressable
      testID="push-toast"
      onPress={() => toast.url && router.push(toast.url as never)}
      accessibilityRole="button"
      accessibilityLabel="Open notification"
      className="absolute top-12 left-4 right-4 bg-white border border-border rounded-xl p-3 z-50"
    >
      <Text testID="push-toast-title" className="text-body font-semibold" numberOfLines={1}>
        {toast.title}
      </Text>
      {toast.body && (
        <Text testID="push-toast-body" className="text-muted text-sm" numberOfLines={2}>
          {toast.body}
        </Text>
      )}
    </Pressable>
  );
}
