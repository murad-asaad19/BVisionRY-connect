import { useEffect, useRef, useState } from 'react';
import { Platform } from 'react-native';
import { router } from 'expo-router';
import { useNextRoute } from '~/features/auth/hooks/useNextRoute';
import { env } from '~/lib/env';
import {
  resolveNotificationRoute,
  type PushDataLike,
} from '~/features/push/services/notificationRoute';

/**
 * Wires Firebase Messaging's tap-to-open handlers to the Expo Router so a
 * background-tap or cold-start notification opens the right screen.
 *
 * Routing prefers the structured `data.kind` + `data.entity_id` /
 * `data.conversation_id` payload (emitted by `dispatch_push` since
 * 20260606150000), and falls back to the legacy `data.url` for older builds.
 *
 * Web is a no-op. Native imports happen lazily so the web bundle doesn't
 * pull in @react-native-firebase/messaging.
 *
 * Race handling: `getInitialNotification` resolves at cold-start before the
 * router and auth-session are guaranteed ready. We stash the deep-link URL in
 * a ref AND bump a `pendingVersion` counter so the drain effect re-runs even
 * when the auth-gate state is already `'app'` at mount (the common
 * "session hydrated from storage before the IIFE resolves" case — without
 * `pendingVersion` the drain effect would fire once with no URL and then
 * never again).
 *
 * Gating: the drain effect gates on `useNextRoute().state === 'app'` rather
 * than on `userId` alone. With a session-only gate, a deep link arriving
 * before onboarding completes would be drained while the `(app)` layout was
 * bouncing the user to `/(onboarding)` — `router.push` would either lose
 * to the redirect or land the user on a route they can't see. Holding the
 * pending URL in the ref until the gate reports the user is allowed into
 * the app routes guarantees the navigation lands somewhere reachable.
 *
 * Background taps (via `onNotificationOpenedApp`) fire after the app is
 * interactive, so they go through the same gate for consistency.
 */
export function useNotificationTapHandler() {
  const { state } = useNextRoute();
  const pendingUrlRef = useRef<string | null>(null);
  const [pendingVersion, setPendingVersion] = useState(0);

  // Subscribe to native messaging events and stash any URL we receive.
  useEffect(() => {
    if (Platform.OS === 'web') return;
    // Firebase disabled (Expo Go or dev shells without GoogleService files):
    // loading @react-native-firebase/messaging would trigger the native
    // RNFBAppModule lookup, which throws when the native modules aren't
    // bundled — surface no-op cleanly.
    if (!env.FIREBASE_ENABLED) return;

    let cancelled = false;
    let unsub: (() => void) | undefined;

    (async () => {
      try {
        const messagingModule = await import('@react-native-firebase/messaging');
        if (cancelled) return;
        const messaging = messagingModule.default;

        // Cold-start: stash for the session-gated effect to drain.
        const initial = await messaging().getInitialNotification();
        if (cancelled) return;
        const initialRoute = resolveNotificationRoute(
          initial?.data as PushDataLike | undefined,
        );
        if (initialRoute) {
          pendingUrlRef.current = initialRoute;
          setPendingVersion((v) => v + 1);
        }

        // Background → foreground via tap.
        unsub = messaging().onNotificationOpenedApp((m) => {
          const route = resolveNotificationRoute(m?.data as PushDataLike | undefined);
          if (route) {
            pendingUrlRef.current = route;
            setPendingVersion((v) => v + 1);
          }
        });
      } catch (e) {
        console.warn('[push] tap handler init failed', e);
      }
    })();

    return () => {
      cancelled = true;
      unsub?.();
    };
  }, []);

  // Drain the pending URL once the auth gate reports `'app'` — i.e. the
  // user has a session AND has completed onboarding AND is not suspended.
  // Without this gate, cold-start would navigate into authed routes before
  // the `(app)` layout finishes its own redirect, losing the deep link.
  // `pendingVersion` ensures we re-run when a URL is stashed AFTER the gate
  // is already `'app'`.
  useEffect(() => {
    if (state !== 'app') return;
    const url = pendingUrlRef.current;
    if (!url) return;
    pendingUrlRef.current = null;
    try {
      router.push(url as never);
    } catch (e) {
      console.warn('[push] router.push from pending notification failed', e);
    }
  }, [state, pendingVersion]);
}
