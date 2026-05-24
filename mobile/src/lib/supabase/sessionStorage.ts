import { Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';

type Storage = {
  getItem: (key: string) => Promise<string | null>;
  setItem: (key: string, value: string) => Promise<void>;
  removeItem: (key: string) => Promise<void>;
};

/**
 * SecureStore on iOS rejects values larger than ~2 KB (the underlying Keychain
 * item-size limit). Supabase access + refresh + provider tokens routinely
 * exceed that, especially with PKCE. We transparently split large values
 * across multiple keys.
 *
 * Layout per logical key:
 *   `${key}-meta`         → `"${count}:${gen}"` — chunk count + generation
 *                           counter (both decimal). Legacy format is a bare
 *                           `${count}` integer; read paths handle both.
 *   `${key}-${gen}-${i}`  → UTF-8 chunks of the original string in order.
 *   `${key}-${i}`         → Legacy chunks from pre-generation writes. Read
 *                           paths fall back to these when meta has no gen.
 *
 * Reads pull every chunk for the meta-recorded generation and concatenate;
 * writes always allocate a NEW generation, write its chunks, swap the meta
 * pointer atomically, then async-cleanup the old generation. We use 1800
 * BYTES (1.8 KB) — the iOS Keychain limit is byte-based, not character-based.
 * JWT payloads encode in Base64URL (ASCII so 1 char = 1 byte) but provider
 * tokens, user metadata, and emoji-bearing claims can include multi-byte
 * UTF-8 sequences, where naive char-slicing would silently overflow the
 * keychain.
 *
 * Atomicity guarantee: a kill mid-write leaves meta pointing at the previous
 * generation's chunks (still intact on disk), so the prior session survives.
 * The single `setItemAsync(meta, ...)` call at the end of `setItem` is the
 * atomic swap — SecureStore writes individual keys atomically on both iOS
 * (Keychain) and Android (EncryptedSharedPreferences). Before that call, the
 * new chunks exist but no reader can see them; after, the new chunks are
 * authoritative and the old ones are dead weight (cleaned up below).
 */
const CHUNK_SIZE = 1800;
const META_SUFFIX = '-meta';
const legacyChunkKey = (key: string, i: number) => `${key}-${i}`;
const genChunkKey = (key: string, gen: number, i: number) => `${key}-${gen}-${i}`;

type Meta = { count: number; gen: number | null };

/** Parse a meta value. Returns null on absent/malformed; `gen: null`
 *  indicates a legacy single-generation write (chunks at `${key}-${i}`). */
function parseMeta(raw: string | null): Meta | null {
  if (raw == null) return null;
  const colon = raw.indexOf(':');
  if (colon === -1) {
    const count = Number.parseInt(raw, 10);
    if (!Number.isFinite(count) || count <= 0) return null;
    return { count, gen: null };
  }
  const count = Number.parseInt(raw.slice(0, colon), 10);
  const gen = Number.parseInt(raw.slice(colon + 1), 10);
  if (!Number.isFinite(count) || count <= 0) return null;
  if (!Number.isFinite(gen) || gen < 0) return null;
  return { count, gen };
}

function formatMeta(count: number, gen: number): string {
  return `${count}:${gen}`;
}

/**
 * Slice a UTF-8 byte array into chunks no larger than `CHUNK_SIZE` bytes,
 * respecting codepoint boundaries. UTF-8 continuation bytes match the
 * top-two-bits pattern `10xxxxxx` — walking backward past those guarantees
 * each slice decodes cleanly without the replacement char (U+FFFD).
 */
function chunkUtf8Bytes(bytes: Uint8Array, chunkSize: number): Uint8Array[] {
  const chunks: Uint8Array[] = [];
  let start = 0;
  while (start < bytes.length) {
    let end = Math.min(start + chunkSize, bytes.length);
    // If we landed mid-codepoint and we're not at the end, walk back to the
    // last codepoint start (byte where the top two bits are NOT `10`).
    if (end < bytes.length) {
      while (end > start && (bytes[end]! & 0xc0) === 0x80) end--;
    }
    // Defensive: if end somehow collapsed to start (a chunkSize smaller than
    // the largest codepoint — can't happen for our 1800-byte size), advance
    // by one byte to avoid an infinite loop. UTF-8 codepoints are <= 4 bytes.
    if (end === start) end = Math.min(start + chunkSize, bytes.length);
    chunks.push(bytes.slice(start, end));
    start = end;
  }
  return chunks;
}

const nativeStorage: Storage = {
  getItem: async (key) => {
    const rawMeta = await SecureStore.getItemAsync(`${key}${META_SUFFIX}`);
    const meta = parseMeta(rawMeta);
    if (meta == null) {
      // Back-compat: tokens written before chunking (single-key direct write).
      // Read whatever's there so existing sessions survive an app upgrade.
      return SecureStore.getItemAsync(key);
    }
    const parts: string[] = [];
    for (let i = 0; i < meta.count; i++) {
      const chunkKey = meta.gen == null ? legacyChunkKey(key, i) : genChunkKey(key, meta.gen, i);
      const part = await SecureStore.getItemAsync(chunkKey);
      if (part == null) {
        // Corrupted/partial write — give up and let supabase re-sign-in.
        return null;
      }
      parts.push(part);
    }
    return parts.join('');
  },

  setItem: async (key, value) => {
    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    const bytes = encoder.encode(value);
    // Always write at least one chunk so getItem can distinguish "stored
    // empty string" from "not stored". `chunkUtf8Bytes` guarantees this for
    // non-empty input; we seed the empty-input case here.
    const byteChunks = bytes.length === 0 ? [new Uint8Array(0)] : chunkUtf8Bytes(bytes, CHUNK_SIZE);

    // Atomic-swap strategy: read the existing meta to learn the old
    // generation, then allocate the NEXT generation, write all its chunks,
    // and finally swap meta. Until the meta write lands, readers continue to
    // see the previous generation. If we crash before the swap, the old
    // session is intact and the orphaned new-gen chunks will be overwritten
    // by the next setItem (which will re-pick `oldGen + 1`).
    const prevMeta = parseMeta(await SecureStore.getItemAsync(`${key}${META_SUFFIX}`));
    const prevGen = prevMeta?.gen ?? null;
    // Start at 0 when migrating from legacy (no gen recorded) or no prior
    // write; otherwise advance by one. Modulo to keep the value bounded
    // across many refresh cycles (a 32-bit space wraps in ~136 yrs at 1
    // write/sec — plenty, but keeping it short avoids unbounded growth in
    // the rare degenerate case).
    const nextGen = prevGen == null ? 0 : (prevGen + 1) % 0x7fffffff;

    for (let i = 0; i < byteChunks.length; i++) {
      await SecureStore.setItemAsync(genChunkKey(key, nextGen, i), decoder.decode(byteChunks[i]!));
    }
    // The atomic swap. After this line, readers see the new generation.
    await SecureStore.setItemAsync(`${key}${META_SUFFIX}`, formatMeta(byteChunks.length, nextGen));

    // Cleanup phase — best-effort, runs AFTER the swap so a crash here
    // leaves stale-but-unreferenced chunks (next setItem will pick yet
    // another fresh gen and we'll never read the orphans).
    if (prevMeta) {
      const cleanupCount = prevMeta.count;
      const cleanupGen = prevMeta.gen;
      for (let i = 0; i < cleanupCount; i++) {
        const staleKey =
          cleanupGen == null ? legacyChunkKey(key, i) : genChunkKey(key, cleanupGen, i);
        await SecureStore.deleteItemAsync(staleKey).catch(() => {});
      }
    }

    // Also wipe any legacy single-key write so reads can't fall back to it.
    await SecureStore.deleteItemAsync(key).catch(() => {});
  },

  removeItem: async (key) => {
    await clearChunks(key);
    await SecureStore.deleteItemAsync(key).catch(() => {});
  },
};

/** Remove every chunk and the meta key. Used by `removeItem`; `setItem`
 *  intentionally uses a generation swap instead so it's atomic. */
async function clearChunks(key: string): Promise<void> {
  const meta = parseMeta(await SecureStore.getItemAsync(`${key}${META_SUFFIX}`));
  if (meta != null) {
    for (let i = 0; i < meta.count; i++) {
      const chunk = meta.gen == null ? legacyChunkKey(key, i) : genChunkKey(key, meta.gen, i);
      await SecureStore.deleteItemAsync(chunk).catch(() => {});
    }
    await SecureStore.deleteItemAsync(`${key}${META_SUFFIX}`).catch(() => {});
  }
}

const webStorage: Storage = {
  getItem: async (key) =>
    typeof window !== 'undefined' && window.localStorage ? window.localStorage.getItem(key) : null,
  setItem: async (key, value) => {
    if (typeof window !== 'undefined' && window.localStorage) {
      window.localStorage.setItem(key, value);
    }
  },
  removeItem: async (key) => {
    if (typeof window !== 'undefined' && window.localStorage) {
      window.localStorage.removeItem(key);
    }
  },
};

export const supabaseSessionStorage: Storage = Platform.OS === 'web' ? webStorage : nativeStorage;
