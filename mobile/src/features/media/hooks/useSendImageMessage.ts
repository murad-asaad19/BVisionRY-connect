import { useMutation, useQueryClient } from '@tanstack/react-query';
import { File } from 'expo-file-system';
import { supabase } from '~/lib/supabase/client';
import { useAuthSession } from '~/features/auth/SessionContext';
import { pickImage } from '~/features/media/hooks/usePickImage';
import { uploadChatMedia } from '~/features/media/services/storage.service';
import { IMAGE_MIME, generateUuid } from '~/features/media/services/media.constants';

/**
 * Image send flow (post-RLS-hardening):
 *   1) Pick + downscale + validate size (handled in pickImage).
 *   2) Generate messageId client-side.
 *   3) Upload to `chat-media/{conversationId}/{messageId}/image.jpg`.
 *   4) Call `send_image_message` SECURITY DEFINER RPC — it extracts the
 *      messageId from the path and inserts the row atomically.
 *   5) Best-effort delete the local temp file.
 *
 * A failed RPC leaves the storage object behind (no orphan message row) —
 * that's intentional. A future cleanup cron can sweep these.
 */
export function useSendImageMessage(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  return useMutation({
    mutationFn: async () => {
      const userId = session?.user.id;
      if (!userId) throw new Error('not signed in');

      const picked = await pickImage();
      if (!picked) return null;

      const messageId = generateUuid();
      const ext: 'jpg' = picked.ext;
      const path = await uploadChatMedia(
        conversationId,
        messageId,
        picked.blob,
        ext,
        IMAGE_MIME.jpg,
        `${messageId}.${ext}`
      );

      try {
        // types.gen.ts hasn't been regenerated for this RPC yet — cast loose.
        const { data, error } = await (supabase.rpc as unknown as (
          fn: string,
          args: Record<string, unknown>
        ) => Promise<{ data: { id: string } | null; error: { message: string } | null }>)(
          'send_image_message',
          {
            p_conversation_id: conversationId,
            p_media_path: path,
            p_media_mime: IMAGE_MIME.jpg,
            p_media_size_bytes: picked.blob.size,
          }
        );
        if (error) throw new Error(error.message);
        return data?.id ?? messageId;
      } finally {
        // Clean up the local manipulated copy regardless of RPC outcome.
        try {
          const tmp = new File(picked.uri);
          if (tmp.exists) tmp.delete();
        } catch {
          // Non-fatal: temp will be GC'd by the OS eventually.
        }
      }
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['messages', conversationId] });
      qc.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}
