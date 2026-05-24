import { useEffect, useRef, useState } from 'react';
import { usePathname } from 'expo-router';
import { onForegroundMessage } from '~/lib/firebase';
import { resolveNotificationRoute } from '~/features/push/services/notificationRoute';

export type ForegroundToast = {
  title: string;
  body: string;
  url?: string;
} | null;

// Note on payload localization:
//
// Push titles/bodies are currently composed in SQL (see `dispatch_push` callers
// in 20260606150000_dispatch_push_payload.sql). Long-term we want clients to
// localize from `data.kind` + `data.entity_id` instead, and the SQL has been
// updated to emit those alongside the legacy fields. This hook prefers the
// structured `data.kind` for routing and falls back to `data.url` for older
// app builds / dev-stub payloads.

/**
 * Subscribes to foreground push messages and exposes the most recent one
 * for display (e.g., in a toast). Auto-clears after 5s.
 *
 * Suppresses the toast when the user is already on the destination route
 * (exact match or a sub-route) — no point flashing a notification for the
 * screen they're already looking at.
 */
export function useForegroundMessages(): ForegroundToast {
  const [toast, setToast] = useState<ForegroundToast>(null);
  const pathname = usePathname();
  // Stash the current pathname in a ref so the message handler (registered
  // once) sees the latest value without re-subscribing on every navigation.
  const pathnameRef = useRef(pathname);
  pathnameRef.current = pathname;
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const unsub = onForegroundMessage((m) => {
      const title = m?.notification?.title ?? (m?.data?.title as string | undefined) ?? '';
      const body = m?.notification?.body ?? (m?.data?.body as string | undefined) ?? '';
      const route = resolveNotificationRoute(m?.data) ?? undefined;
      if (!title && !body) return;

      // Skip the toast if the user is already on the destination screen.
      // Only applies when we resolved a route — otherwise we can't know
      // what the toast refers to and we'd rather show it than drop it.
      if (route) {
        const here = pathnameRef.current ?? '';
        if (here === route || here.startsWith(route + '/')) return;
      }

      setToast({ title, body, url: route });
      if (timerRef.current) clearTimeout(timerRef.current);
      timerRef.current = setTimeout(() => {
        setToast(null);
        timerRef.current = null;
      }, 5000);
    });
    return () => {
      unsub();
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    };
  }, []);

  return toast;
}
