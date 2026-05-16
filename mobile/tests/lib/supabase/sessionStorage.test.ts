jest.mock('expo-secure-store', () => ({
  getItemAsync: jest.fn(),
  setItemAsync: jest.fn(),
  deleteItemAsync: jest.fn(),
}));

import * as SecureStore from 'expo-secure-store';
import { supabaseSessionStorage } from '~/lib/supabase/sessionStorage';

describe('supabaseSessionStorage (native)', () => {
  beforeEach(() => jest.clearAllMocks());

  it('getItem reads from SecureStore', async () => {
    (SecureStore.getItemAsync as jest.Mock).mockResolvedValueOnce('value');
    const result = await supabaseSessionStorage.getItem('key');
    expect(SecureStore.getItemAsync).toHaveBeenCalledWith('key');
    expect(result).toBe('value');
  });

  it('setItem writes to SecureStore', async () => {
    (SecureStore.setItemAsync as jest.Mock).mockResolvedValueOnce(undefined);
    await supabaseSessionStorage.setItem('key', 'value');
    expect(SecureStore.setItemAsync).toHaveBeenCalledWith('key', 'value');
  });

  it('removeItem deletes from SecureStore', async () => {
    (SecureStore.deleteItemAsync as jest.Mock).mockResolvedValueOnce(undefined);
    await supabaseSessionStorage.removeItem('key');
    expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith('key');
  });
});
