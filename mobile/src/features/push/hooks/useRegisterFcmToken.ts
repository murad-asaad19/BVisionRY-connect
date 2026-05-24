import { useEffect, useRef } from 'react';
import { Platform, PermissionsAndroid } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useAuthSession } from '~/features/auth/SessionContext';
import { getFcmToken } from '~/lib/firebase';
import { registerDeviceToken } from '~/features/push/services/push.service';
import { setLast, clear as clearLast } from '~/features/push/services/lastTokenStorage';
import type { DevicePlatform } from '~/features/push/services/push.service';

// TODO(firebase): production builds need real google-services.json /
// GoogleService-Info.plist resolved via EAS secrets at build time. The
// placeholder files in mobile/ are dev-only; do not ship them.

function platformValue(): DevicePlatform | null {
  if (Platform.OS === 'android') return 'android';
  if (Platform.OS === 'ios') return 'ios';
  return null; // web: skip
}

/**
 * On Android 13+ (API 33), POST_NOTIFICATIONS is a runtime permission distinct
 * from the FCM auth status. Older RNFirebase versions do NOT request it
 * automatically, so we request it before attempting `getToken`.
 * Returns true if granted (or not required), false otherwise.
 */
async function ensureAndroidNotificationsPermission(t: (k: string) => string): Promise<boolean> {
  if (Platform.OS !== 'android') return true;
  // Platform.Version is a number on Android.
  const version = typeof Platform.Version === 'number' ? Platform.Version : parseInt(String(Platform.Version), 10);
  if (Number.isNaN(version) || version < 33) return true;
  try {
    const status = await PermissionsAndroid.request(
      PermissionsAndroid.PERMISSIONS.POST_NOTIFICATIONS,
      {
        title: t('push.permissionDeniedTitle'),
        message: t('push.permissionDeniedBody'),
        buttonPositive: 'OK',
      }
    );
    return status === PermissionsAndroid.RESULTS.GRANTED;
  } catch (e) {
    console.warn('[push] POST_NOTIFICATIONS request failed', e);
    return false;
  }
}

/**
 * Captures the FCM token once a session is established and upserts it via RPC.
 * Also subscribes to `onTokenRefresh` so we re-register when FCM rotates tokens
 * (e.g., app reinstall, data clear, or push-service maintenance).
 *
 * Web is a no-op. Errors are swallowed (logged) to avoid blocking auth flows.
 *
 * `t` (the i18next translator) is read via a ref so a language change does
 * NOT re-trigger the whole register flow — the effect should only re-run when
 * the user identity changes. Only the strings used inside the Android
 * permission dialog need to be current at request time, and that happens on
 * the next register cycle naturally.
 *
 * The most recently registered token is persisted to AsyncStorage via
 * `lastTokenStorage` so sign-out can deregister it without round-tripping to
 * FCM (which would otherwise force `messaging().requestPermission()` at the
 * worst possible time).
 */
export function useRegisterFcmToken() {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const { t } = useTranslation();
  const tRef = useRef(t);
  tRef.current = t;

  useEffect(() => {
    if (!userId) return;
    const platform = platformValue();
    if (!platform) return;

    let cancelled = false;
    let unsubRefresh: (() => void) | undefined;

    (async () => {
      try {
        const allowed = await ensureAndroidNotificationsPermission(tRef.current);
        if (!allowed) {
          console.warn('[push] POST_NOTIFICATIONS denied; skipping registration');
          // No valid token registered for this user — clear any stale entry so
          // signOut doesn't try to deregister a token that isn't ours.
          await clearLast();
          return;
        }
        const token = await getFcmToken();
        if (cancelled) return;
        if (token) {
          await registerDeviceToken(token, platform);
          await setLast(token);
        } else {
          await clearLast();
        }
      } catch (e) {
        console.warn('[push] register token failed', e);
      }

      // Subscribe to token rotation. Use a dynamic import so the web bundle
      // doesn't pull in @react-native-firebase/messaging (the lib shim only
      // exposes the web no-ops).
      if (Platform.OS === 'web' || cancelled) return;
      try {
        const messagingModule = await import('@react-native-firebase/messaging');
        if (cancelled) return;
        const messaging = messagingModule.default;
        unsubRefresh = messaging().onTokenRefresh(async (next: string) => {
          try {
            await registerDeviceToken(next, platform);
            await setLast(next);
          } catch (e) {
            console.warn('[push] token-refresh re-register failed', e);
          }
        });
      } catch (e) {
        console.warn('[push] onTokenRefresh subscription failed', e);
      }
    })();

    return () => {
      cancelled = true;
      unsubRefresh?.();
    };
  }, [userId]);
}
