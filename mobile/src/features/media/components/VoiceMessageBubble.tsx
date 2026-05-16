import { useState, useEffect } from 'react';
import { View, Text, Pressable } from 'react-native';
import { useAudioPlayer, useAudioPlayerStatus } from 'expo-audio';
import { getChatMediaSignedUrl } from '~/features/media/services/storage.service';

type Props = {
  mediaPath: string;
  durationMs: number;
  isMine: boolean;
  transcript?: string | null;
  transcriptStatus?: string | null;
};

function fmt(ms: number) {
  const s = Math.round(ms / 1000);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

function statusText(status: string | null | undefined): string {
  switch (status) {
    case 'pending':
      return 'Transcript pending…';
    case 'failed':
      return 'Transcript unavailable';
    case 'unsupported':
      return 'Transcript not available in dev';
    default:
      return 'Transcript unavailable';
  }
}

/**
 * Phase 2 voice bubble with Phase 3 transcript reveal.
 * Visual: 28px play button (gold for me-bubble, navy for them-bubble),
 * waveform strip, duration label. Transcript reveal renders as a side-anchored
 * card (max-w-80%) matching the bubble side, white-bordered with TRANSCRIPT
 * label — mockup F3.
 */
export function VoiceMessageBubble({
  mediaPath,
  durationMs,
  isMine,
  transcript,
  transcriptStatus,
}: Props) {
  const [url, setUrl] = useState<string | null>(null);
  const [showTranscript, setShowTranscript] = useState(false);

  useEffect(() => {
    let cancelled = false;
    getChatMediaSignedUrl(mediaPath)
      .then((u) => {
        if (!cancelled) setUrl(u);
      })
      .catch(() => {
        // signed URL failed; toggle stays disabled
      });
    return () => {
      cancelled = true;
    };
  }, [mediaPath]);

  const player = useAudioPlayer(url ?? undefined);
  const status = useAudioPlayerStatus(player);

  const toggle = () => {
    if (!url) return;
    if (status.playing) player.pause();
    else player.play();
  };

  const hasTranscriptInfo =
    (transcript !== undefined && transcript !== null) ||
    (transcriptStatus !== undefined && transcriptStatus !== null);

  const readyTranscript = transcriptStatus === 'ready' && transcript ? transcript : null;
  const transcriptBody = readyTranscript ?? statusText(transcriptStatus);

  return (
    <View className={isMine ? 'self-end' : 'self-start'}>
      <View
        testID={isMine ? 'voice-bubble-mine' : 'voice-bubble-theirs'}
        className={`flex-row items-center min-w-[200px] max-w-[280px] px-3 py-2 my-1 rounded-2xl ${
          isMine ? 'bg-navy rounded-br-sm' : 'bg-white border border-border rounded-bl-sm'
        }`}
      >
        <Pressable
          testID="voice-toggle"
          onPress={toggle}
          accessibilityRole="button"
          accessibilityLabel="Play voice message"
          className={`w-7 h-7 rounded-full items-center justify-center mr-2 ${
            isMine ? 'bg-gold' : 'bg-navy'
          }`}
        >
          <Text className={`font-display-bold text-[12px] ${isMine ? 'text-navy' : 'text-gold'}`}>
            {status.playing ? '||' : '▶'}
          </Text>
        </Pressable>
        <View
          className={`flex-1 h-[18px] rounded ${isMine ? 'bg-navy-light' : 'bg-slate-100'} mr-2`}
        />
        <Text className={`font-body text-[10px] ${isMine ? 'text-gold-light' : 'text-muted'}`}>
          {fmt(durationMs)}
        </Text>
      </View>

      {hasTranscriptInfo ? (
        <View className={isMine ? 'self-end' : 'self-start'}>
          <Pressable
            testID="voice-transcript-toggle"
            onPress={() => setShowTranscript((v) => !v)}
            accessibilityRole="button"
            accessibilityLabel={showTranscript ? 'Hide transcript' : 'Show transcript'}
          >
            <Text
              className={`font-body text-[10px] ${isMine ? 'text-right' : 'text-left'} text-muted underline mt-1`}
            >
              {showTranscript ? 'Hide transcript' : 'Show transcript'}
            </Text>
          </Pressable>
          {showTranscript ? (
            <View
              testID="voice-transcript-banner"
              className="bg-white border border-border rounded-xl px-3 py-2 max-w-[80%] mt-1"
            >
              <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-0.5">
                Transcript
              </Text>
              <Text className="font-body text-[11px] text-body leading-snug">{transcriptBody}</Text>
              <Text className="font-body text-[10px] text-muted mt-1.5 leading-snug">
                Voice notes are transcribed for accessibility and safety.
              </Text>
            </View>
          ) : null}
        </View>
      ) : null}
    </View>
  );
}
