import { useState } from 'react';
import { useAudioRecorder, useAudioRecorderState, RecordingPresets } from 'expo-audio';

export function useRecordAudio() {
  const recorder = useAudioRecorder(RecordingPresets.HIGH_QUALITY);
  const recorderState = useAudioRecorderState(recorder);
  const [startedAt, setStartedAt] = useState<number | null>(null);

  const start = async () => {
    await recorder.prepareToRecordAsync();
    recorder.record();
    setStartedAt(Date.now());
  };

  const stop = async (): Promise<{ uri: string; durationMs: number } | null> => {
    if (!recorderState.isRecording) return null;
    await recorder.stop();
    const uri = recorder.uri;
    if (!uri) return null;
    const durationMs = startedAt ? Date.now() - startedAt : 0;
    setStartedAt(null);
    return { uri, durationMs };
  };

  return { start, stop, isRecording: recorderState.isRecording };
}
