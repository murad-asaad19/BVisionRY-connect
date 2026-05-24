import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Alert } from 'react-native';
import { File } from 'expo-file-system';
import { supabase } from '~/lib/supabase/client';
import { useAuthSession } from '~/features/auth/SessionContext';
import { uploadChatMedia } from '~/features/media/services/storage.service';
import {
  MAX_VOICE_BYTES,
  MAX_VOICE_MS,
  VOICE_MIME,
  generateUuid,
} from '~/features/media/services/media.constants';
import { i18n } from '~/lib/i18n';

/**
 * Voice send flow (post-RLS-hardening):
 *   1) Validate duration + size client-side.
 *   2) Generate messageId client-side.
 *   3) Upload to `chat-media/{conversationId}/{messageId}/voice.m4a`.
 *   4) Call `send_voice_message` SECURITY DEFINER RPC — it extracts the
 *      messageId from the path and inserts the row atomically; the existing
 *      AFTER-INSERT trigger dispatches transcription with the same id.
 *   5) Best-effort delete the recorded temp file.
 */
export function useSendVoiceMessage(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  return useMutation({
    mutationFn: async (recording: { uri: string; durationMs: number }) => {
      const userId = session?.user.id;
      if (!userId) throw new Error('not signed in');

      const durationMs = Math.round(recording.durationMs);
      if (durationMs > MAX_VOICE_MS) {
        Alert.alert(
          i18n.t('media.voiceTooLongTitle'),
          i18n.t('media.voiceTooLongBody', { maxMinutes: Math.round(MAX_VOICE_MS / 60_000) })
        );
        return null;
      }

      const blob = await fetch(recording.uri).then((r) => r.blob());
      if (blob.size > MAX_VOICE_BYTES) {
        Alert.alert(
          i18n.t('media.voiceTooLargeTitle'),
          i18n.t('media.voiceTooLargeBody', { maxMb: Math.round(MAX_VOICE_BYTES / (1024 * 1024)) })
        );
        return null;
      }

      const messageId = generateUuid();
      const ext: 'm4a' = 'm4a';
      const path = await uploadChatMedia(
        conversationId,
        messageId,
        blob,
        ext,
        VOICE_MIME.m4a,
        `${messageId}.${ext}`
      );

      try {
        const { data, error } = await (supabase.rpc as unknown as (
          fn: string,
          args: Record<string, unknown>
        ) => Promise<{ data: { id: string } | null; error: { message: string } | null }>)(
          'send_voice_message',
          {
            p_conversation_id: conversationId,
            p_media_path: path,
            p_media_mime: VOICE_MIME.m4a,
            p_media_size_bytes: blob.size,
            p_duration_ms: durationMs,
          }
        );
        if (error) throw new Error(error.message);
        return data?.id ?? messageId;
      } finally {
        try {
          const tmp = new File(recording.uri);
          if (tmp.exists) tmp.delete();
        } catch {
          // Non-fatal.
        }
      }
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['messages', conversationId] });
      qc.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}
