import { useEffect, useState } from 'react';
import { View, Text, Pressable, ActivityIndicator } from 'react-native';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { useRecordAudio } from '~/features/media/hooks/useRecordAudio';
import { useSendVoiceMessage } from '~/features/media/hooks/useSendVoiceMessage';

type Props = { conversationId: string };

const MAX_MS = 2 * 60 * 1000;

function fmtElapsed(ms: number) {
  const s = Math.floor(ms / 1000);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

/**
 * Phase 2 voice recorder. Replaces the inline VoiceRecorderControl button +
 * captures audio inside a BottomSheet with a pulse + timer + Cancel/Send row.
 * Keeps the `composer-voice` testID so playwright continues to find it.
 */
export function VoiceRecorderSheet({ conversationId }: Props) {
  const { start, stop, isRecording } = useRecordAudio();
  const send = useSendVoiceMessage(conversationId);

  const [open, setOpen] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!open || !isRecording) return;
    const t0 = Date.now();
    const id = setInterval(() => setElapsed(Date.now() - t0), 250);
    return () => clearInterval(id);
  }, [open, isRecording]);

  const onOpen = async () => {
    setElapsed(0);
    setOpen(true);
    await start();
  };

  const onCancel = async () => {
    if (isRecording) await stop();
    setOpen(false);
  };

  const onSend = async () => {
    if (!isRecording) {
      setOpen(false);
      return;
    }
    setSubmitting(true);
    try {
      const rec = await stop();
      if (rec) await send.mutateAsync(rec);
    } finally {
      setSubmitting(false);
      setOpen(false);
    }
  };

  return (
    <>
      <Pressable
        testID="composer-voice"
        onPress={onOpen}
        accessibilityRole="button"
        accessibilityLabel="Record voice message"
        className="w-7 h-7 rounded-full bg-gold-pale items-center justify-center"
      >
        <Text className="text-navy text-[14px]">🎤</Text>
      </Pressable>

      <BottomSheet visible={open} onClose={onCancel} testID="voice-recorder-sheet">
        <View className="items-center pt-2 pb-4">
          <View className="w-20 h-20 rounded-full bg-danger-bg border-2 border-danger-text items-center justify-center mb-3">
            {/* Filled red dot — mockup F2 */}
            <View testID="voice-recorder-pulse" className="w-7 h-7 rounded-full bg-danger-text" />
          </View>
          <Text testID="voice-recorder-timer" className="font-display-bold text-[22px] text-navy">
            {fmtElapsed(elapsed)} / {fmtElapsed(MAX_MS)}
          </Text>
          <Text className="font-body text-[10px] text-muted mt-1 text-center px-6 leading-snug">
            Max 2 minutes — voice notes are transcribed for accessibility & safety.
          </Text>
          <View className="flex-row gap-1 mt-3 h-4 items-end">
            {Array.from({ length: 14 }).map((_, i) => (
              <View
                key={i}
                style={{ height: 6 + ((i * 5) % 12) }}
                className="w-1 bg-gold rounded-sm"
              />
            ))}
          </View>
        </View>
        <View className="flex-row gap-3">
          <View className="flex-1">
            <Button
              testID="voice-recorder-cancel"
              variant="outline"
              onPress={onCancel}
              disabled={submitting}
            >
              Cancel
            </Button>
          </View>
          <View className="flex-1">
            <Button
              testID="voice-recorder-send"
              variant="primary"
              onPress={onSend}
              loading={submitting}
            >
              Send
            </Button>
          </View>
        </View>
        {submitting ? (
          <View className="mt-2 items-center">
            <ActivityIndicator color="#0f3460" />
          </View>
        ) : null}
      </BottomSheet>
    </>
  );
}
