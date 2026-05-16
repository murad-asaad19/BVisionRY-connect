import { useEffect, useState } from 'react';
import { onForegroundMessage } from '~/lib/firebase';

export type ForegroundToast = {
  title: string;
  body: string;
  url?: string;
} | null;

/**
 * Subscribes to foreground push messages and exposes the most recent one
 * for display (e.g., in a toast). Auto-clears after 5s.
 */
export function useForegroundMessages(): ForegroundToast {
  const [toast, setToast] = useState<ForegroundToast>(null);

  useEffect(() => {
    const unsub = onForegroundMessage((m) => {
      const title = m?.notification?.title ?? (m?.data?.title as string | undefined) ?? '';
      const body = m?.notification?.body ?? (m?.data?.body as string | undefined) ?? '';
      const url = (m?.data?.url as string | undefined) ?? undefined;
      if (!title && !body) return;
      setToast({ title, body, url });
      const id = setTimeout(() => setToast(null), 5000);
      return () => clearTimeout(id);
    });
    return unsub;
  }, []);

  return toast;
}
