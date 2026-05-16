import { useState } from 'react';
import { View, TextInput, Pressable, Text, ActivityIndicator } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useSendMessage } from '~/features/chat/hooks/useSendMessage';
import { ProposeMeetingSheet } from '~/features/meetings/components/ProposeMeetingSheet';
import { useSendImageMessage } from '~/features/media/hooks/useSendImageMessage';
import { VoiceRecorderSheet } from '~/features/media/components/VoiceRecorderSheet';

type Props = { conversationId: string; onTyping?: () => void };

export function MessageComposer({ conversationId, onTyping }: Props) {
  const { t } = useTranslation();
  const [body, setBody] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [proposeOpen, setProposeOpen] = useState(false);
  const send = useSendMessage(conversationId);
  const sendImage = useSendImageMessage(conversationId);

  const onSend = async () => {
    const trimmed = body.trim();
    if (!trimmed) return;
    if (trimmed.length > 4000) {
      setError('Message too long (max 4000 characters).');
      return;
    }
    setError(null);
    try {
      await send.mutateAsync(trimmed);
      setBody('');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Send failed');
    }
  };

  const sendDisabled = send.isPending || body.trim().length === 0;

  return (
    <View className="border-t border-border px-3 py-2 bg-white">
      {error && (
        <Text testID="composer-error" className="text-danger-text text-[11px] mb-1.5 font-body">
          {error}
        </Text>
      )}
      <View className="flex-row items-center gap-1.5">
        <Pressable
          testID="composer-propose"
          onPress={() => setProposeOpen(true)}
          accessibilityRole="button"
          accessibilityLabel="Propose meeting"
          className="w-7 h-7 rounded-full bg-gold-pale items-center justify-center"
        >
          <Text className="text-navy text-[14px]">+</Text>
        </Pressable>
        <Pressable
          testID="composer-image"
          onPress={() => sendImage.mutate()}
          disabled={sendImage.isPending}
          accessibilityRole="button"
          accessibilityLabel="Send photo"
          className="w-7 h-7 rounded-full bg-gold-pale items-center justify-center"
        >
          {sendImage.isPending ? (
            <ActivityIndicator color="#0f3460" />
          ) : (
            <Text className="text-navy text-[12px]">📷</Text>
          )}
        </Pressable>
        <VoiceRecorderSheet conversationId={conversationId} />
        <TextInput
          testID="composer-input"
          value={body}
          onChangeText={(nextBody) => {
            setBody(nextBody);
            setError(null);
            if (nextBody.length > 0) onTyping?.();
          }}
          placeholder={t('chat.composerPlaceholder')}
          placeholderTextColor="#94a3b8"
          multiline
          maxLength={4000}
          className="flex-1 bg-white border border-border rounded-2xl px-3 py-2 text-[12px] text-body font-body max-h-32"
          style={{ textAlignVertical: 'top' }}
        />
        <Pressable
          testID="composer-send"
          onPress={onSend}
          disabled={sendDisabled}
          accessibilityRole="button"
          accessibilityLabel="Send message"
          className={`w-7 h-7 rounded-full items-center justify-center ${
            sendDisabled ? 'bg-slate-300' : 'bg-navy'
          }`}
        >
          {send.isPending ? (
            <ActivityIndicator color="#ffffff" />
          ) : (
            <Text className="font-display-bold text-[14px] text-white leading-none">→</Text>
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
