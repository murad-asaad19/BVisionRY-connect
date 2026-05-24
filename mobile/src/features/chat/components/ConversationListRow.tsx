import { memo } from 'react';
import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { BellOff } from 'lucide-react-native';
import { Avatar } from '~/components/ui/Avatar';
import { Pill } from '~/components/ui/Pill';
import { colors } from '~/theme/colors';
import type { MessageKind } from '~/features/chat/services/chat.service';

type Props = {
  peerName: string;
  peerHandle: string;
  peerPhotoUrl: string | null;
  /**
   * Preview of the last message body. For non-text kinds, this is `null`
   * and the row falls back to a kind-specific i18n string (e.g. "Photo").
   */
  lastMessagePreview: string | null;
  /** Kind of the most recent message; used to format the preview text. */
  lastMessageKind?: MessageKind | null;
  unreadCount?: number;
  isMuted?: boolean;
  onPress: () => void;
};

function ConversationListRowImpl({
  peerName,
  peerHandle,
  peerPhotoUrl,
  lastMessagePreview,
  lastMessageKind,
  unreadCount = 0,
  isMuted = false,
  onPress,
}: Props) {
  const { t } = useTranslation();
  const hasUnread = unreadCount > 0;

  // Resolve the preview line. Text messages show the body; other kinds
  // show a localised placeholder ("Photo", "Voice message", "Meeting").
  let preview: string | null = null;
  if (lastMessagePreview !== null && lastMessagePreview !== undefined) {
    preview = lastMessagePreview;
  } else if (lastMessageKind === 'image') {
    preview = t('chat.previewImage');
  } else if (lastMessageKind === 'voice') {
    preview = t('chat.previewVoice');
  } else if (lastMessageKind === 'meeting') {
    preview = t('chat.previewMeeting');
  }

  return (
    <Pressable
      testID={`conversation-row-${peerHandle}`}
      onPress={onPress}
      className="flex-row items-center bg-white border border-border rounded-xl px-4 py-3 mx-gutter mb-3 active:bg-slate-100"
    >
      <Avatar name={peerName} photoUrl={peerPhotoUrl} size={48} />
      <View className="ml-4 flex-1">
        <View className="flex-row items-center">
          <Text
            className="font-body-semibold text-display-sm text-body flex-1"
            numberOfLines={1}
          >
            {peerName}
          </Text>
          {isMuted && (
            <View testID="conversation-row-muted" className="ml-2">
              <BellOff size={14} color={colors.muted} />
            </View>
          )}
        </View>
        <Text className="text-muted text-body-sm" numberOfLines={1}>
          @{peerHandle}
        </Text>
        {preview !== null && (
          <Text className="text-muted text-body-md mt-1" numberOfLines={1}>
            {preview}
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

export const ConversationListRow = memo(ConversationListRowImpl);
