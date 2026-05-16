import { supabase } from '~/lib/supabase/client';

const MIME: Record<string, string> = {
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  webp: 'image/webp',
  m4a: 'audio/m4a',
  mp4: 'audio/mp4',
  webm: 'audio/webm',
  aac: 'audio/aac',
};

export async function uploadAvatar(userId: string, blob: Blob, ext: string): Promise<string> {
  const path = `${userId}/avatar-${Date.now()}.${ext}`;
  const contentType = MIME[ext] ?? 'application/octet-stream';
  const bucket = supabase.storage.from('avatars');
  const { error } = await bucket.upload(path, blob, { contentType, upsert: true });
  if (error) throw new Error(error.message);
  const { data } = bucket.getPublicUrl(path);
  return data.publicUrl;
}

export async function uploadChatMedia(
  conversationId: string,
  messageId: string,
  blob: Blob,
  ext: string,
  contentType: string
): Promise<string> {
  const uniq =
    globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const path = `${conversationId}/${messageId}/${uniq}.${ext}`;
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
