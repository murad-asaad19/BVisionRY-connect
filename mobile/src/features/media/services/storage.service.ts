import { supabase } from '~/lib/supabase/client';
import { mimeFor } from '~/features/media/services/media.constants';

/**
 * Upload an avatar to the public `avatars` bucket. We use a stable filename
 * (`{userId}/avatar.{ext}`) with `upsert: true` so we never accumulate
 * per-timestamp files. The returned URL has `?v=<now>` appended so clients
 * that previously cached the old image bust their cache.
 */
export async function uploadAvatar(userId: string, blob: Blob, ext: string): Promise<string> {
  const safeExt = ext.toLowerCase();
  const path = `${userId}/avatar.${safeExt}`;
  const contentType = mimeFor(safeExt);
  const bucket = supabase.storage.from('avatars');
  const { error } = await bucket.upload(path, blob, { contentType, upsert: true });
  if (error) throw new Error(error.message);
  const { data } = bucket.getPublicUrl(path);
  // Cache-bust to defeat the device-level image cache after re-upload.
  return `${data.publicUrl}?v=${Date.now()}`;
}

/**
 * Upload to chat-media at the canonical path
 *   `{conversationId}/{messageId}/{filename}`
 * `messageId` is generated client-side BEFORE the row is inserted so the
 * upload + the SECURITY DEFINER RPC (send_image_message / send_voice_message)
 * are an atomic pair: a failed RPC may leave an orphan storage object, but
 * never an orphan message row.
 */
export async function uploadChatMedia(
  conversationId: string,
  messageId: string,
  blob: Blob,
  ext: string,
  contentType: string,
  filename = `media.${ext}`
): Promise<string> {
  const safeExt = ext.toLowerCase();
  const path = `${conversationId}/${messageId}/${filename.endsWith(`.${safeExt}`) ? filename : `media.${safeExt}`}`;
  const bucket = supabase.storage.from('chat-media');
  const { error } = await bucket.upload(path, blob, { contentType });
  if (error) throw new Error(error.message);
  return path;
}

export function getChatMediaSignedUrl(path: string, expiresIn = 3600): Promise<string> {
  return supabase.storage
    .from('chat-media')
    .createSignedUrl(path, expiresIn)
    .then(({ data, error }) => {
      if (error) throw new Error(error.message);
      return data.signedUrl;
    });
}
