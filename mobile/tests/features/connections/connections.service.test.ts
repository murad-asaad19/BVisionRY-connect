jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn() },
}));
import { supabase } from '~/lib/supabase/client';
import { listConnections } from '~/features/connections/services/connections.service';

describe('connections.service', () => {
  beforeEach(() => jest.clearAllMocks());
  it('listConnections returns rows', async () => {
    const rows = [
      {
        user_id: 'u1',
        handle: 'a',
        name: 'Alice',
        photo_url: null,
        primary_role: 'builder',
        conversation_id: 'c1',
        connected_at: 't',
      },
    ];
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: rows, error: null });
    expect(await listConnections()).toEqual(rows);
  });
  it('throws on error', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: { message: 'oops' } });
    await expect(listConnections()).rejects.toThrow('oops');
  });
});
