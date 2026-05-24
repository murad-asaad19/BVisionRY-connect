import { useCallback, useEffect, useRef, useState } from 'react';
import { Alert, AppState, type AppStateStatus, Linking, Platform } from 'react-native';
import {
  RecordingPresets,
  requestRecordingPermissionsAsync,
  setAudioModeAsync,
  useAudioRecorder,
  useAudioRecorderState,
} from 'expo-audio';
import { i18n } from '~/lib/i18n';

export type RecordedClip = { uri: string; durationMs: number };

/**
 * Microphone recording lifecycle, hardened against the common foot-guns:
 *  1) Requests RECORD_AUDIO permission FIRST and surfaces an Open-Settings
 *     alert on denial (iOS + Android).
 *  2) Configures the audio session for recording (`allowsRecording: true`,
 *     `playsInSilentMode: true`) — required for iOS to actually capture audio.
 *  3) Stops the recorder if the app backgrounds mid-recording.
 *  4) Stops the recorder on unmount so a dropped sheet can't leave a
 *     dangling capture session.
 */
export function useRecordAudio() {
  const recorder = useAudioRecorder(RecordingPresets.HIGH_QUALITY);
  const recorderState = useAudioRecorderState(recorder);
  const [startedAt, setStartedAt] = useState<number | null>(null);

  // Refs the AppState listener can read without re-subscribing every render.
  const isRecordingRef = useRef(false);
  isRecordingRef.current = recorderState.isRecording;
  const recorderRef = useRef(recorder);
  recorderRef.current = recorder;
  const startedAtRef = useRef<number | null>(null);
  startedAtRef.current = startedAt;

  const stopInternal = useCallback(async (): Promise<RecordedClip | null> => {
    if (!isRecordingRef.current) return null;
    try {
      await recorderRef.current.stop();
    } catch {
      // Best-effort stop; surface nothing.
    }
    const uri = recorderRef.current.uri;
    const start = startedAtRef.current;
    const durationMs = start ? Date.now() - start : 0;
    setStartedAt(null);
    if (!uri) return null;
    return { uri, durationMs };
  }, []);

  // Auto-stop on background + on unmount. Mount-only effect.
  useEffect(() => {
    const onChange = (state: AppStateStatus) => {
      if (state !== 'active' && isRecordingRef.current) {
        void stopInternal();
      }
    };
    const sub = AppState.addEventListener('change', onChange);
    return () => {
      sub.remove();
      if (isRecordingRef.current) void stopInternal();
    };
  }, [stopInternal]);

  const surfaceDenied = useCallback(() => {
    Alert.alert(
      i18n.t('media.permissionMicTitle'),
      i18n.t('media.permissionMicBody'),
      [
        { text: i18n.t('media.cancel'), style: 'cancel' },
        {
          text: i18n.t('media.openSettings'),
          onPress: () => {
            if (Platform.OS === 'web') return;
            void Linking.openSettings();
          },
        },
      ]
    );
  }, []);

  const start = useCallback(async (): Promise<boolean> => {
    const perm = await requestRecordingPermissionsAsync();
    if (perm.status !== 'granted') {
      surfaceDenied();
      return false;
    }
    try {
      await setAudioModeAsync({
        allowsRecording: true,
        playsInSilentMode: true,
      });
    } catch {
      // Non-fatal: best effort. iOS may still record without the mode set
      // (Android ignores most of these flags).
    }
    await recorderRef.current.prepareToRecordAsync();
    recorderRef.current.record();
    setStartedAt(Date.now());
    return true;
  }, [surfaceDenied]);

  const stop = useCallback(async (): Promise<RecordedClip | null> => {
    const clip = await stopInternal();
    try {
      // Restore non-recording mode so a subsequent playback isn't muted in
      // silent mode on iOS.
      await setAudioModeAsync({
        allowsRecording: false,
        playsInSilentMode: true,
      });
    } catch {
      // ignore
    }
    return clip;
  }, [stopInternal]);

  return { start, stop, isRecording: recorderState.isRecording };
}
