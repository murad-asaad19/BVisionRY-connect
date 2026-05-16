import { useEffect } from 'react';
import { Platform } from 'react-native';
import { router } from 'expo-router';

/**
 * Wires Firebase Messaging's tap-to-open handlers to the Expo Router so a
 * background-tap or cold-start notification with a `data.url` field opens
 * the right screen.
 *
 * Web is a no-op. Native imports happen lazily so the web bundle doesn't
 * pull in @react-native-firebase/messaging.
 */
export function useNotificationTapHandler() {
  useEffect(() => {
    if (Platform.OS === 'web') return;

    let unsub: (() => void) | undefined;
    (async () => {
      try {
        const messagingModule = await import('@react-native-firebase/messaging');
        const messaging = messagingModule.default;

        // Cold-start
        const initial = await messaging().getInitialNotification();
        const url = initial?.data?.url;
        if (typeof url === 'string') router.push(url as never);

        // Background → foreground via tap
        unsub = messaging().onNotificationOpenedApp((m) => {
          const u = m?.data?.url;
          if (typeof u === 'string') router.push(u as never);
        });
      } catch (e) {
        console.warn('[push] tap handler init failed', e);
      }
    })();

    return () => {
      unsub?.();
    };
  }, []);
}
