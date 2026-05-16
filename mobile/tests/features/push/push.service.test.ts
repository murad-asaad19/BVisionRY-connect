jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import { registerDeviceToken } from '~/features/push/services/push.service';

describe('push.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('calls register_device_token RPC with token + platform', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: { id: 'd1' }, error: null });
    await registerDeviceToken('a'.repeat(32), 'android');
    expect(supabase.rpc).toHaveBeenCalledWith('register_device_token', {
      p_token: 'a'.repeat(32),
      p_platform: 'android',
    });
  });

  it('throws on RPC error', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: { message: 'oops' } });
    await expect(registerDeviceToken('a'.repeat(32), 'android')).rejects.toThrow('oops');
  });
});
