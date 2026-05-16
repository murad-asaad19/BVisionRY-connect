jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    from: jest.fn(),
    rpc: jest.fn(),
    functions: { invoke: jest.fn() },
    auth: { signOut: jest.fn(), getSession: jest.fn() },
  },
}));

import { supabase } from '~/lib/supabase/client';
import {
  updateNotificationPrefs,
  exportMyData,
  deleteMyAccount,
} from '~/features/settings/services/settings.service';

describe('settings.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('updateNotificationPrefs writes to profile row', async () => {
    const eq = jest.fn().mockResolvedValue({ error: null });
    const update = jest.fn().mockReturnValue({ eq });
    (supabase.from as jest.Mock).mockReturnValue({ update });
    await updateNotificationPrefs('user-1', { notify_intro: false });
    expect(supabase.from).toHaveBeenCalledWith('profiles');
    expect(update).toHaveBeenCalledWith({ notify_intro: false });
    expect(eq).toHaveBeenCalledWith('id', 'user-1');
  });

  it('exportMyData returns rpc data', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValue({ data: { foo: 1 }, error: null });
    const result = await exportMyData();
    expect(supabase.rpc).toHaveBeenCalledWith('export_my_data');
    expect(result).toEqual({ foo: 1 });
  });

  it('deleteMyAccount invokes edge function then signs out', async () => {
    (supabase.functions.invoke as jest.Mock).mockResolvedValue({ data: 'ok', error: null });
    (supabase.auth.signOut as jest.Mock).mockResolvedValue({ error: null });
    await deleteMyAccount();
    expect(supabase.functions.invoke).toHaveBeenCalledWith('delete-account', { method: 'POST' });
    expect(supabase.auth.signOut).toHaveBeenCalled();
  });

  it('deleteMyAccount throws on edge function error', async () => {
    (supabase.functions.invoke as jest.Mock).mockResolvedValue({
      data: null,
      error: { message: 'bad' },
    });
    await expect(deleteMyAccount()).rejects.toThrow('bad');
  });
});
