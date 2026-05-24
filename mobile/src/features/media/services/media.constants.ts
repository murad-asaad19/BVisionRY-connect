// Shared media limits + MIME tables — kept in lockstep with the server
// constraints in supabase/migrations/20260606110000_media_message_rpcs.sql
// (image <=5MB, voice <=25MB / <=2min) and the chat-media bucket allowlist
// in 20260524000000_slice13_media.sql.

export const MAX_VOICE_MS = 120_000;
export const MAX_VOICE_BYTES = 25 * 1024 * 1024;
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const MAX_AVATAR_BYTES = 5 * 1024 * 1024;

export const IMAGE_MIME = {
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  webp: 'image/webp',
} as const;

export const VOICE_MIME = {
  m4a: 'audio/m4a',
  mp4: 'audio/mp4',
  aac: 'audio/aac',
  webm: 'audio/webm',
} as const;

export type ImageExt = keyof typeof IMAGE_MIME;
export type VoiceExt = keyof typeof VOICE_MIME;

export const MIME_BY_EXT: Record<string, string> = {
  ...IMAGE_MIME,
  ...VOICE_MIME,
};

export function mimeFor(ext: string): string {
  return MIME_BY_EXT[ext.toLowerCase()] ?? 'application/octet-stream';
}

/** Generate a v4 uuid. Falls back to a hand-rolled v4 if neither
 *  `crypto.randomUUID` nor `expo-crypto` is present. */
export function generateUuid(): string {
  const cryptoObj = (globalThis as { crypto?: { randomUUID?: () => string } }).crypto;
  if (cryptoObj?.randomUUID) return cryptoObj.randomUUID();
  // RFC 4122 v4 fallback (rare path: very old JSCore on Android <= 10)
  const bytes = new Uint8Array(16);
  for (let i = 0; i < 16; i += 1) bytes[i] = Math.floor(Math.random() * 256);
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
