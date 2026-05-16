jest.mock('~/lib/supabase/client', () => ({
  supabase: { from: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import { fetchProfileByHandle } from '~/features/profile/hooks/useProfileByHandle';

describe('fetchProfileByHandle', () => {
  beforeEach(() => jest.clearAllMocks());

  it('queries profiles by handle and returns single row', async () => {
    const single = jest.fn().mockResolvedValueOnce({
      data: { id: 'u1', handle: 'alice', name: 'Alice' },
      error: null,
    });
    const eq = jest.fn().mockReturnValue({ single });
    const select = jest.fn().mockReturnValue({ eq });
    (supabase.from as jest.Mock).mockReturnValue({ select });

    const result = await fetchProfileByHandle('alice');
    expect(supabase.from).toHaveBeenCalledWith('profiles');
    expect(eq).toHaveBeenCalledWith('handle', 'alice');
    expect(result?.handle).toBe('alice');
  });

  it('returns null when profile not found (PGRST116)', async () => {
    const single = jest.fn().mockResolvedValueOnce({
      data: null,
      error: { code: 'PGRST116', message: 'not found' },
    });
    const eq = jest.fn().mockReturnValue({ single });
    const select = jest.fn().mockReturnValue({ eq });
    (supabase.from as jest.Mock).mockReturnValue({ select });

    const result = await fetchProfileByHandle('ghost');
    expect(result).toBeNull();
  });

  it('throws on other errors', async () => {
    const single = jest.fn().mockResolvedValueOnce({
      data: null,
      error: { code: 'PGRST500', message: 'server error' },
    });
    const eq = jest.fn().mockReturnValue({ single });
    const select = jest.fn().mockReturnValue({ eq });
    (supabase.from as jest.Mock).mockReturnValue({ select });

    await expect(fetchProfileByHandle('alice')).rejects.toThrow('server error');
  });
});
