import { useEffect, useMemo, useState } from 'react';
import * as Linking from 'expo-linking';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '~/lib/supabase/client';
import { createSessionFromUrl } from '~/features/auth/services/auth.service';

/**
 * Is this URL an auth callback? OAuth/magic-link callbacks always land on the
 * `/auth` path (see `~/features/auth/services/redirect.ts`). Other deep links
 * (e.g. `/p/handle` profile shares) must NOT trigger a session exchange —
 * doing so wastes an RPC, can flash the auth screen, and on malformed payloads
 * would surface a spurious error.
 *
 * `/auth` matches both:
 *   - native scheme:    `connect-mobile://auth?code=...`  (//auth contains /auth)
 *   - universal link:   `https://host/auth?code=...`
 */
function isAuthCallbackUrl(url: string): boolean {
  return url.includes('/auth');
}

export function useSession() {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    // Register the auth listener SYNCHRONOUSLY first so we don't race the
    // bootstrap below. The listener is authoritative for non-null sessions
    // (e.g. the SIGNED_IN event after a deep-link exchange); bootstrap fills
    // in the initial value if nothing has arrived yet.
    //
    // NOTE: we intentionally DO NOT toggle `loading` here. On a cold-start
    // deep-link install the SDK fires `INITIAL_SESSION` with a null session
    // (storage is empty) BEFORE bootstrap finishes exchanging the code —
    // clearing `loading` from this callback would let the auth gate flash
    // the sign-in screen before the magic link resolves.
    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      if (cancelled) return;
      setSession(newSession);
    });

    // Bootstrap deals with cold-start deep links (magic link / OAuth callback)
    // and gives us a session fallback if no auth event ever fires (e.g. the
    // user is signed out and never has been).
    (async () => {
      try {
        const initialUrl = await Linking.getInitialURL();
        // Only run the session exchange for auth callbacks — a cold-start
        // `/p/handle` URL must not pay the cost of, or risk an error from,
        // `createSessionFromUrl`. The initial `loading=true` covers the
        // skip case (we still settle below via `setLoading(false)`).
        if (initialUrl && isAuthCallbackUrl(initialUrl)) {
          await createSessionFromUrl(initialUrl).catch((e) =>
            console.warn('[auth] deep-link session error', e)
          );
        }
        const { data } = await supabase.auth.getSession();
        if (cancelled) return;
        // Only set if the listener hasn't already produced a session — this
        // avoids a redundant render and the brief flicker of a stale state.
        setSession((prev) => prev ?? data.session);
        setLoading(false);
      } catch (e) {
        console.warn('[auth] initial session error', e);
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
      sub.subscription.unsubscribe();
    };
  }, []);

  // Subsequent deep links (after mount — native cold-link follow-ups or web hash changes).
  useEffect(() => {
    const handler = ({ url }: { url: string }) => {
      // Non-auth deep links (e.g. /p/handle shares) must not trigger the
      // session exchange. Gating here also means we only raise `loading` for
      // auth URLs — keeping it down for routing-only links so screens that
      // depend on a settled `loading=false` don't flicker.
      if (!isAuthCallbackUrl(url)) return;
      setLoading(true);
      createSessionFromUrl(url)
        .catch((e) => console.warn('[auth] deep-link session error', e))
        .finally(() => setLoading(false));
    };
    const sub = Linking.addEventListener('url', handler);
    return () => sub.remove();
  }, []);

  // Stable object so consumers (e.g. SessionProvider) can memoize off this.
  return useMemo(() => ({ session, loading }), [session, loading]);
}
