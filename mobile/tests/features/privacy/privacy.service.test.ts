jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  blockUser,
  unblockUser,
  listBlockedUsers,
  reportTarget,
} from '~/features/privacy/services/privacy.service';

describe('privacy.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('blockUser calls RPC', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
    await blockUser('user-id');
    expect(supabase.rpc).toHaveBeenCalledWith('block_user', { p_target: 'user-id' });
  });

  it('blockUser throws on error', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: { message: 'no' } });
    await expect(blockUser('user-id')).rejects.toThrow('no');
  });

  it('unblockUser calls RPC', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
    await unblockUser('user-id');
    expect(supabase.rpc).toHaveBeenCalledWith('unblock_user', { p_target: 'user-id' });
  });

  it('listBlockedUsers returns rows', async () => {
    const rows = [{ blocked_id: 'u1', handle: 'h', name: 'n', photo_url: null, created_at: 't' }];
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: rows, error: null });
    const result = await listBlockedUsers();
    expect(result).toEqual(rows);
  });

  it('reportTarget calls RPC with args', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
    await reportTarget('profile', 'user-id', 'spam', 'note here');
    expect(supabase.rpc).toHaveBeenCalledWith('report_target', {
      p_target_type: 'profile',
      p_target_id: 'user-id',
      p_reason: 'spam',
      p_note: 'note here',
    });
  });
});
