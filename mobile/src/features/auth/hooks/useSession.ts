import { useEffect, useState } from 'react';
import * as Linking from 'expo-linking';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '~/lib/supabase/client';
import { createSessionFromUrl } from '~/features/auth/services/auth.service';

export function useSession() {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    // Resolve any incoming deep-link session BEFORE flipping loading=false,
    // otherwise the auth gate may render with session=null and redirect to
    // sign-in before the magic-link hash has been consumed.
    (async () => {
      try {
        const initialUrl = await Linking.getInitialURL();
        if (initialUrl) {
          await createSessionFromUrl(initialUrl).catch((e) =>
            console.warn('[auth] deep-link session error', e)
          );
        }
        const { data } = await supabase.auth.getSession();
        if (!cancelled) {
          setSession(data.session);
          setLoading(false);
        }
      } catch (e) {
        console.warn('[auth] initial session error', e);
        if (!cancelled) setLoading(false);
      }
    })();

    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      if (!cancelled) setSession(newSession);
    });

    return () => {
      cancelled = true;
      sub.subscription.unsubscribe();
    };
  }, []);

  // Subsequent deep links (after mount — native cold-link follow-ups or web hash changes).
  useEffect(() => {
    const handler = ({ url }: { url: string }) => {
      createSessionFromUrl(url).catch((e) => console.warn('[auth] deep-link session error', e));
    };
    const sub = Linking.addEventListener('url', handler);
    return () => sub.remove();
  }, []);

  return { session, loading };
}
