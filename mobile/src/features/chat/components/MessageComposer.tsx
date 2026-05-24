import { useState } from 'react';
import { View, TextInput, Text, ActivityIndicator, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Plus, Camera, Send } from 'lucide-react-native';
import { useSendMessage, newMessageId } from '~/features/chat/hooks/useSendMessage';
import { ProposeMeetingSheet } from '~/features/meetings/components/ProposeMeetingSheet';
import { useSendImageMessage } from '~/features/media/hooks/useSendImageMessage';
import { VoiceRecorderSheet } from '~/features/media/components/VoiceRecorderSheet';
import { IconButton } from '~/components/ui/IconButton';
import { colors } from '~/theme/colors';

type Props = {
  conversationId: string;
  onTyping?: () => void;
  onStoppedTyping?: () => void;
};

export function MessageComposer({ conversationId, onTyping, onStoppedTyping }: Props) {
  const { t } = useTranslation();
  const [body, setBody] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [proposeOpen, setProposeOpen] = useState(false);
  const send = useSendMessage(conversationId);
  const sendImage = useSendImageMessage(conversationId);

  const onSend = async () => {
    const trimmed = body.trim();
    if (!trimmed) return;
    setError(null);
    // Optimistic UI clears the input immediately; rollback on error
    // restores the cache so the bubble disappears.
    setBody('');
    onStoppedTyping?.();
    try {
      await send.mutateAsync({ body: trimmed, tempId: newMessageId() });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Send failed');
      // Keep the trimmed text in the input so the user can retry.
      setBody(trimmed);
    }
  };

  const sendDisabled = send.isPending || body.trim().length === 0;

  return (
    <View className="border-t border-border px-3 py-2 bg-white">
      {error && (
        <Text testID="composer-error" className="font-body text-body-sm text-danger-text mb-1.5">
          {error}
        </Text>
      )}
      <View className="flex-row items-center gap-1.5">
        <IconButton
          testID="composer-propose"
          icon={Plus}
          size="sm"
          variant="subtle"
          label="Propose meeting"
          onPress={() => setProposeOpen(true)}
        />
        {sendImage.isPending ? (
          <View
            testID="composer-image-pending"
            className="w-8 h-8 rounded-full bg-slate-100 items-center justify-center"
          >
            <ActivityIndicator color={colors.navy} />
          </View>
        ) : (
          <IconButton
            testID="composer-image"
            icon={Camera}
            size="sm"
            variant="subtle"
            label="Send photo"
            onPress={() => sendImage.mutate()}
            disabled={sendImage.isPending}
          />
        )}
        <VoiceRecorderSheet conversationId={conversationId} />
        <TextInput
          testID="composer-input"
          value={body}
          onChangeText={(nextBody) => {
            setBody(nextBody);
            setError(null);
            // `TextInput.maxLength` and the DB constraint already enforce
            // the 4000-char ceiling; no JS length check needed here.
            if (nextBody.length > 0) onTyping?.();
            else onStoppedTyping?.();
          }}
          onBlur={() => onStoppedTyping?.()}
          placeholder={t('chat.composerPlaceholder')}
          placeholderTextColor={colors.muted}
          multiline
          maxLength={4000}
          className="flex-1 bg-white border border-border rounded-2xl px-3 py-2 font-body text-body-md text-body max-h-32"
          style={{ textAlignVertical: 'top' }}
        />
        <Pressable
          testID="composer-send"
          onPress={onSend}
          disabled={sendDisabled}
          accessibilityRole="button"
          accessibilityLabel="Send message"
          className={`w-10 h-10 rounded-full items-center justify-center ${
            sendDisabled ? 'bg-slate-300' : 'bg-navy'
          }`}
        >
          {send.isPending ? (
            <ActivityIndicator color={colors.white} />
          ) : (
            <Send size={16} color={colors.white} />
          )}
        </Pressable>
      </View>

      <ProposeMeetingSheet
        visible={proposeOpen}
        conversationId={conversationId}
        onClose={() => setProposeOpen(false)}
        onSent={() => setProposeOpen(false)}
      />
    </View>
  );
}
