jest.mock('expo-secure-store', () => ({
  getItemAsync: jest.fn(),
  setItemAsync: jest.fn(),
  deleteItemAsync: jest.fn(),
}));

import * as SecureStore from 'expo-secure-store';
import { supabaseSessionStorage } from '~/lib/supabase/sessionStorage';

describe('supabaseSessionStorage (native, chunked)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default: deleteItemAsync resolves cleanly; impl uses `.catch(() => {})`.
    (SecureStore.deleteItemAsync as jest.Mock).mockResolvedValue(undefined);
    (SecureStore.setItemAsync as jest.Mock).mockResolvedValue(undefined);
  });

  describe('getItem', () => {
    it('returns null and falls back to a direct legacy read when no meta exists', async () => {
      (SecureStore.getItemAsync as jest.Mock)
        .mockResolvedValueOnce(null) // key-meta
        .mockResolvedValueOnce('legacy-value'); // key (direct)

      const result = await supabaseSessionStorage.getItem('key');

      expect(SecureStore.getItemAsync).toHaveBeenNthCalledWith(1, 'key-meta');
      expect(SecureStore.getItemAsync).toHaveBeenNthCalledWith(2, 'key');
      expect(result).toBe('legacy-value');
    });

    it('reads legacy bare-int meta ("3") via the unprefixed chunk path', async () => {
      // Legacy format: meta is a bare integer count and chunks live at
      // `${key}-${i}` (no generation segment). Old sessions written before the
      // atomic-generation-counter refactor must still be readable so users
      // don't get logged out on app upgrade.
      (SecureStore.getItemAsync as jest.Mock)
        .mockResolvedValueOnce('3') // key-meta (legacy bare-int)
        .mockResolvedValueOnce('alpha-')
        .mockResolvedValueOnce('beta-')
        .mockResolvedValueOnce('gamma');

      const result = await supabaseSessionStorage.getItem('key');

      expect(result).toBe('alpha-beta-gamma');
      expect(SecureStore.getItemAsync).toHaveBeenCalledWith('key-0');
      expect(SecureStore.getItemAsync).toHaveBeenCalledWith('key-1');
      expect(SecureStore.getItemAsync).toHaveBeenCalledWith('key-2');
    });

    it('concatenates chunks for a generation-formatted meta ("2:1")', async () => {
      // New layout: meta is "count:gen". Chunks live under the
      // `${key}-${gen}-${i}` namespace; reads must NOT fall back to the bare
      // `${key}-${i}` keys (those may be from an unrelated prior generation).
      (SecureStore.getItemAsync as jest.Mock)
        .mockResolvedValueOnce('2:1') // key-meta
        .mockResolvedValueOnce('hello-')
        .mockResolvedValueOnce('world');

      const result = await supabaseSessionStorage.getItem('key');

      expect(result).toBe('hello-world');
      expect(SecureStore.getItemAsync).toHaveBeenCalledWith('key-1-0');
      expect(SecureStore.getItemAsync).toHaveBeenCalledWith('key-1-1');
      // Defensive: must not fall back to bare-key reads.
      expect(SecureStore.getItemAsync).not.toHaveBeenCalledWith('key-0');
      expect(SecureStore.getItemAsync).not.toHaveBeenCalledWith('key-1');
    });

    it('returns null if a chunk is missing (partial write)', async () => {
      (SecureStore.getItemAsync as jest.Mock)
        .mockResolvedValueOnce('2:0') // meta
        .mockResolvedValueOnce('first')
        .mockResolvedValueOnce(null);

      const result = await supabaseSessionStorage.getItem('key');
      expect(result).toBeNull();
    });
  });

  describe('setItem', () => {
    it('writes a single chunk under gen-0 and records meta "1:0" on first write', async () => {
      (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce(null); // no prior meta
      await supabaseSessionStorage.setItem('key', 'tiny');

      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-0-0', 'tiny');
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-meta', '1:0');
    });

    it('splits oversized values into 1800-byte chunks under the new generation', async () => {
      (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce(null); // no prior meta
      const value = 'x'.repeat(1800 * 2 + 50);
      await supabaseSessionStorage.setItem('key', value);

      // 3 chunks: 1800 + 1800 + 50, all under gen 0.
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-0-0', expect.any(String));
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-0-1', expect.any(String));
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-0-2', expect.any(String));
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-meta', '3:0');
    });

    it('advances the generation on a subsequent write and deletes prior-gen chunks after the meta swap', async () => {
      // Prior write left meta "4:0" pointing at gen-0 chunks key-0-0..key-0-3.
      (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce('4:0');
      await supabaseSessionStorage.setItem('key', 'short');

      // New write goes to gen 1 (prev gen 0 + 1).
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-1-0', 'short');
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-meta', '1:1');

      // Cleanup of the four prior gen-0 chunks happens AFTER the atomic
      // meta swap — best-effort, so a crash here is harmless.
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0-0');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0-1');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0-2');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0-3');
      // Legacy bare-key direct write (pre-chunking) is wiped as a final step.
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key');
      // The meta key itself is NOT deleted — it's overwritten by the swap.
      expect(SecureStore.deleteItemAsync).not.toHaveBeenCalledWith('key-meta');
    });

    it('migrates from legacy bare-int meta ("3") to gen-0 chunks', async () => {
      // prevMeta has no gen → nextGen should start at 0, and cleanup should
      // hit the legacy bare-key chunks (key-0, key-1, key-2), NOT the new
      // gen-prefixed ones we just wrote.
      (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce('3');
      await supabaseSessionStorage.setItem('key', 'small');

      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-0-0', 'small');
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-meta', '1:0');

      // Legacy chunks are at the bare-key namespace and must be cleaned up.
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-1');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-2');
    });

    it('leaves prior-generation chunks intact when the meta swap throws (crash mid-write)', async () => {
      // Atomicity guarantee: until the meta swap lands, readers continue to
      // see the previous generation. Simulate a crash by making the meta
      // setItemAsync reject — the cleanup phase must NOT run.
      (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce('2:0');
      (SecureStore.setItemAsync as jest.Mock).mockImplementation((k: string) =>
        k === 'key-meta'
          ? Promise.reject(new Error('boom: keychain failure during meta swap'))
          : Promise.resolve(undefined)
      );

      await expect(supabaseSessionStorage.setItem('key', 'new')).rejects.toThrow('boom');

      // New-gen chunks were written before the swap…
      expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key-1-0', 'new');
      // …but prior-gen chunks were NOT deleted, so the old session survives.
      expect(SecureStore.deleteItemAsync).not.toHaveBeenCalledWith('key-0-0');
      expect(SecureStore.deleteItemAsync).not.toHaveBeenCalledWith('key-0-1');
    });
  });

  describe('removeItem', () => {
    it('removes all gen-prefixed chunks and the meta key', async () => {
      (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce('2:0');
      await supabaseSessionStorage.removeItem('key');

      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0-0');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0-1');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-meta');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key');
    });

    it('removes legacy bare-key chunks when meta is the bare-int format', async () => {
      (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce('2');
      await supabaseSessionStorage.removeItem('key');

      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-0');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-1');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key-meta');
      expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key');
    });
  });
});
