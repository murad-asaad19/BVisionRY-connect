import firebase from '@react-native-firebase/app';
import analytics from '@react-native-firebase/analytics';
import crashlytics from '@react-native-firebase/crashlytics';
import messaging from '@react-native-firebase/messaging';
import type { FirebaseMessagingTypes } from '@react-native-firebase/messaging';
import { env } from '~/lib/env';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

let initialized = false;

export async function initFirebase(): Promise<void> {
  if (initialized) return;
  if (!env.FIREBASE_ENABLED) {
    // Wiring is in place but disabled until real config files are dropped in.
    return;
  }
  // Best-effort opt-out: read persisted prefs synchronously. If the Zustand
  // store hasn't rehydrated from AsyncStorage yet, defaults to false
  // (opt-out for GDPR). Pref changes via Settings take effect on the NEXT
  // app launch.
  const prefs = useTelemetryStore.getState();
  await analytics().setAnalyticsCollectionEnabled(prefs.analyticsEnabled);
  await crashlytics().setCrashlyticsCollectionEnabled(prefs.crashReportsEnabled);
  initialized = true;
  if (__DEV__) {
    console.log('[firebase] initialized', firebase.app().name);
  }
}

export async function getFcmToken(): Promise<string | null> {
  if (!env.FIREBASE_ENABLED) return null;
  try {
    const authStatus = await messaging().requestPermission();
    const enabled =
      authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
      authStatus === messaging.AuthorizationStatus.PROVISIONAL;
    if (!enabled) return null;
    return await messaging().getToken();
  } catch (e) {
    console.warn('[firebase] getFcmToken failed', e);
    return null;
  }
}

export function onForegroundMessage(
  handler: (message: FirebaseMessagingTypes.RemoteMessage) => void
): () => void {
  if (!env.FIREBASE_ENABLED) return () => {};
  return messaging().onMessage(handler);
}

/**
 * Subscribe to FCM token rotation events. Returns an unsubscribe function.
 * No-op when Firebase is disabled (returns an unsubscribe that does nothing).
 *
 * Note: cross-platform consumers should NOT import this from `~/lib/firebase`
 * because the lib-agent-owned `index.ts` shim only re-exports the web no-ops.
 * Prefer a dynamic `import('@react-native-firebase/messaging')` gated on
 * `Platform.OS !== 'web'` in the consumer.
 */
export function subscribeToTokenRefresh(cb: (token: string) => void): () => void {
  if (!env.FIREBASE_ENABLED) return () => {};
  return messaging().onTokenRefresh(cb);
}
