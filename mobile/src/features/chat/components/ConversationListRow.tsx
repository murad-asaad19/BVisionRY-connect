import { View, Text, Pressable } from 'react-native';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { Pill } from '~/components/ui/Pill';

type Props = {
  peerName: string;
  peerHandle: string;
  peerPhotoUrl: string | null;
  lastMessagePreview: string | null;
  unreadCount?: number;
  isMuted?: boolean;
  onPress: () => void;
};

export function ConversationListRow({
  peerName,
  peerHandle,
  peerPhotoUrl,
  lastMessagePreview,
  unreadCount = 0,
  isMuted = false,
  onPress,
}: Props) {
  const hasUnread = unreadCount > 0;
  return (
    <Pressable
      testID={`conversation-row-${peerHandle}`}
      onPress={onPress}
      className="flex-row items-center bg-white border border-border rounded-xl px-4 py-3 mx-6 mb-3"
    >
      <AvatarCircle name={peerName} photoUrl={peerPhotoUrl} size={48} />
      <View className="ml-4 flex-1">
        <View className="flex-row items-center">
          <Text className="text-body font-semibold flex-1" numberOfLines={1}>
            {peerName}
          </Text>
          {isMuted && (
            <Text testID="conversation-row-muted" className="text-muted text-xs ml-2">
              🔇
            </Text>
          )}
        </View>
        <Text className="text-muted text-xs" numberOfLines={1}>
          @{peerHandle}
        </Text>
        {lastMessagePreview !== null && (
          <Text className="text-muted text-sm mt-1" numberOfLines={1}>
            {lastMessagePreview}
          </Text>
        )}
      </View>
      {hasUnread && (
        <View className="ml-2">
          <Pill variant="navy" testID="conversation-row-unread-badge">
            {unreadCount > 99 ? '99+' : unreadCount}
          </Pill>
        </View>
      )}
    </Pressable>
  );
}
