import { Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';

type Storage = {
  getItem: (key: string) => Promise<string | null>;
  setItem: (key: string, value: string) => Promise<void>;
  removeItem: (key: string) => Promise<void>;
};

const nativeStorage: Storage = {
  getItem: (key) => SecureStore.getItemAsync(key),
  setItem: async (key, value) => {
    await SecureStore.setItemAsync(key, value);
  },
  removeItem: async (key) => {
    await SecureStore.deleteItemAsync(key);
  },
};

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
