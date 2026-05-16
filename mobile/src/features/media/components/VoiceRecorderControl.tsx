import { useState } from 'react';
import { Pressable, Text, ActivityIndicator } from 'react-native';
import { useRecordAudio } from '~/features/media/hooks/useRecordAudio';
import { useSendVoiceMessage } from '~/features/media/hooks/useSendVoiceMessage';

type Props = { conversationId: string };

export function VoiceRecorderControl({ conversationId }: Props) {
  const { start, stop, isRecording } = useRecordAudio();
  const send = useSendVoiceMessage(conversationId);
  const [submitting, setSubmitting] = useState(false);

  const onPress = async () => {
    if (!isRecording) {
      await start();
    } else {
      setSubmitting(true);
      try {
        const rec = await stop();
        if (rec) await send.mutateAsync(rec);
      } finally {
        setSubmitting(false);
      }
    }
  };

  return (
    <Pressable
      testID="composer-voice"
      onPress={onPress}
      disabled={submitting}
      className={`px-3 py-2 rounded-2xl items-center justify-center ${
        isRecording ? 'bg-danger-bg' : 'bg-white border border-border'
      }`}
    >
      {submitting ? (
        <ActivityIndicator color="#fff" />
      ) : (
        <Text className="text-body">{isRecording ? '⏹' : '🎤'}</Text>
      )}
    </Pressable>
  );
}
