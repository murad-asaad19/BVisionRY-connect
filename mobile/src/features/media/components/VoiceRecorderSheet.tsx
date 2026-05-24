import { useEffect, useRef, useState } from 'react';
import { View, Text, Pressable, ActivityIndicator } from 'react-native';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { colors } from '~/theme/colors';
import { useRecordAudio } from '~/features/media/hooks/useRecordAudio';
import { useSendVoiceMessage } from '~/features/media/hooks/useSendVoiceMessage';
import { MAX_VOICE_MS } from '~/features/media/services/media.constants';

type Props = { conversationId: string };

function fmtElapsed(ms: number) {
  const s = Math.floor(ms / 1000);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

/**
 * Phase 2 voice recorder. Replaces the inline VoiceRecorderControl button +
 * captures audio inside a BottomSheet with a pulse + timer + Cancel/Send row.
 * Keeps the `composer-voice` testID so playwright continues to find it.
 *
 * Auto-stops + sends when `elapsed >= MAX_VOICE_MS` so we never blow past the
 * server-side 2-minute limit.
 */
export function VoiceRecorderSheet({ conversationId }: Props) {
  const { start, stop, isRecording } = useRecordAudio();
  const send = useSendVoiceMessage(conversationId);

  const [open, setOpen] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const [submitting, setSubmitting] = useState(false);

  // Avoid double-fire of auto-send when the interval ticks past MAX while a
  // user-initiated send is already in flight.
  const sendingRef = useRef(false);

  const finalizeAndSend = async () => {
    if (sendingRef.current) return;
    sendingRef.current = true;
    setSubmitting(true);
    try {
      const rec = await stop();
      if (rec) await send.mutateAsync(rec);
    } finally {
      sendingRef.current = false;
      setSubmitting(false);
      setOpen(false);
    }
  };

  useEffect(() => {
    if (!open || !isRecording) return;
    const t0 = Date.now();
    const id = setInterval(() => {
      const ms = Date.now() - t0;
      setElapsed(ms);
      if (ms >= MAX_VOICE_MS) {
        clearInterval(id);
        void finalizeAndSend();
      }
    }, 250);
    return () => clearInterval(id);
    // We intentionally exclude `finalizeAndSend` from deps — it closes over
    // mutate/stop refs that don't need to re-arm the interval.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, isRecording]);

  const onOpen = async () => {
    setElapsed(0);
    const ok = await start();
    if (!ok) return; // Permission denied — alert already surfaced.
    setOpen(true);
  };

  const onCancel = async () => {
    if (sendingRef.current) return;
    if (isRecording) await stop();
    setOpen(false);
  };

  const onSend = async () => {
    if (!isRecording) {
      setOpen(false);
      return;
    }
    await finalizeAndSend();
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
            {fmtElapsed(elapsed)} / {fmtElapsed(MAX_VOICE_MS)}
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
            <ActivityIndicator color={colors.navy} />
          </View>
        ) : null}
      </BottomSheet>
    </>
  );
}
