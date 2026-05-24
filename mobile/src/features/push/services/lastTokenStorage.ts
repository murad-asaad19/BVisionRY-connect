import AsyncStorage from '@react-native-async-storage/async-storage';

/**
 * Persists the most recently registered FCM token in AsyncStorage.
 *
 * Why: sign-out needs to deregister the device-token, but calling
 * `getFcmToken()` triggers `messaging().requestPermission()` and a network
 * round-trip to FCM — undesirable side effects on logout, and broken when
 * the user has since revoked the notification permission. By stashing the
 * token at registration time we can deregister it offline.
 */

const LAST_TOKEN_KEY = '@push/last-token';

export async function setLast(token: string): Promise<void> {
  try {
    await AsyncStorage.setItem(LAST_TOKEN_KEY, token);
  } catch (e) {
    console.warn('[push] lastTokenStorage.setLast failed', e);
  }
}

export async function getLast(): Promise<string | null> {
  try {
    return await AsyncStorage.getItem(LAST_TOKEN_KEY);
  } catch (e) {
    console.warn('[push] lastTokenStorage.getLast failed', e);
    return null;
  }
}

export async function clear(): Promise<void> {
  try {
    await AsyncStorage.removeItem(LAST_TOKEN_KEY);
  } catch (e) {
    console.warn('[push] lastTokenStorage.clear failed', e);
  }
}
