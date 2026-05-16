jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    rpc: jest.fn(),
    from: jest.fn(),
  },
}));

import { supabase } from '~/lib/supabase/client';
import {
  checkHandleAvailable,
  fetchProfile,
  updateProfile,
} from '~/features/profile/services/profile.service';

describe('profile.service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('checkHandleAvailable', () => {
    it('returns true when RPC says handle is free', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: true, error: null });
      const result = await checkHandleAvailable('alice');
      expect(supabase.rpc).toHaveBeenCalledWith('check_handle_available', { p_handle: 'alice' });
      expect(result).toBe(true);
    });

    it('returns false when handle is taken', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: false, error: null });
      expect(await checkHandleAvailable('alice')).toBe(false);
    });

    it('throws on RPC error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'rpc fail' },
      });
      await expect(checkHandleAvailable('alice')).rejects.toThrow('rpc fail');
    });
  });

  describe('fetchProfile', () => {
    it('fetches profile by user id', async () => {
      const single = jest.fn().mockResolvedValueOnce({
        data: { id: 'u1', email: 'a@b.com', name: 'Ahmad', onboarded: true },
        error: null,
      });
      const eq = jest.fn().mockReturnValue({ single });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchProfile('u1');
      expect(supabase.from).toHaveBeenCalledWith('profiles');
      expect(select).toHaveBeenCalledWith('*');
      expect(eq).toHaveBeenCalledWith('id', 'u1');
      expect(result?.id).toBe('u1');
    });

    it('throws on fetch error', async () => {
      const single = jest.fn().mockResolvedValueOnce({ data: null, error: { message: 'denied' } });
      const eq = jest.fn().mockReturnValue({ single });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });
      await expect(fetchProfile('u1')).rejects.toThrow('denied');
    });
  });

  describe('updateProfile', () => {
    it('patches profile row by id', async () => {
      const single = jest.fn().mockResolvedValueOnce({
        data: { id: 'u1', name: 'New Name' },
        error: null,
      });
      const select = jest.fn().mockReturnValue({ single });
      const eq = jest.fn().mockReturnValue({ select });
      const update = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ update });

      const result = await updateProfile('u1', { name: 'New Name' });
      expect(update).toHaveBeenCalledWith({ name: 'New Name' });
      expect(eq).toHaveBeenCalledWith('id', 'u1');
      expect(result.name).toBe('New Name');
    });
  });
});
