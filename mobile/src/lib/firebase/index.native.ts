import { env } from '~/lib/env';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

// IMPORTANT: top-level imports of `@react-native-firebase/*` would crash the
// JS bundle on environments that lack the native modules — most notably
// Expo Go, which has no way to ship arbitrary native code. Every Firebase
// dependency below is therefore lazy-loaded via `require()` inside the
// function that needs it, AND each function short-circuits before that
// require when `env.FIREBASE_ENABLED` is false. That keeps Expo Go (where
// FIREBASE_ENABLED is always false) from ever reaching the require.
// Production EAS builds set FIREBASE_ENABLED=true and ship the native
// modules, so the require resolves normally.

type FirebaseMessagingTypes = typeof import('@react-native-firebase/messaging') extends {
  FirebaseMessagingTypes: infer T;
}
  ? T
  : never;
type RemoteMessage = {
  data?: Record<string, string>;
  notification?: { title?: string; body?: string };
  [k: string]: unknown;
};

let initialized = false;

export async function initFirebase(): Promise<void> {
  if (initialized) return;
  if (!env.FIREBASE_ENABLED) return;

  const firebase = require('@react-native-firebase/app').default;
  const analytics = require('@react-native-firebase/analytics').default;
  const crashlytics = require('@react-native-firebase/crashlytics').default;

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
    const messaging = require('@react-native-firebase/messaging').default;
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
  handler: (message: RemoteMessage) => void
): () => void {
  if (!env.FIREBASE_ENABLED) return () => {};
  const messaging = require('@react-native-firebase/messaging').default;
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
  const messaging = require('@react-native-firebase/messaging').default;
  return messaging().onTokenRefresh(cb);
}

export type { RemoteMessage };
