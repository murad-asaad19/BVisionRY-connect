import { useState } from 'react';
import { Pressable, ActivityIndicator, View } from 'react-native';
import { Mic, Square } from 'lucide-react-native';
import { useRecordAudio } from '~/features/media/hooks/useRecordAudio';
import { useSendVoiceMessage } from '~/features/media/hooks/useSendVoiceMessage';
import { colors } from '~/theme/colors';

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

  const Icon = isRecording ? Square : Mic;
  const iconColor = isRecording ? colors.danger : colors.navy;

  return (
    <Pressable
      testID="composer-voice"
      onPress={onPress}
      disabled={submitting}
      accessibilityRole="button"
      accessibilityLabel={isRecording ? 'Stop recording' : 'Record voice message'}
      className={`px-3 py-2 rounded-2xl items-center justify-center ${
        isRecording ? 'bg-danger-bg' : 'bg-white border border-border'
      }`}
    >
      {submitting ? (
        <ActivityIndicator color={colors.white} />
      ) : (
        <View pointerEvents="none">
          <Icon size={16} color={iconColor} />
        </View>
      )}
    </Pressable>
  );
}
