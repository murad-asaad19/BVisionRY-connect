import 'react-native-url-polyfill/auto';
import { AppState, Platform } from 'react-native';
import { createClient } from '@supabase/supabase-js';
import { env } from '~/lib/env';
import { supabaseSessionStorage } from '~/lib/supabase/sessionStorage';
import type { Database } from './types.gen';

export const supabase = createClient<Database>(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
  auth: {
    storage: supabaseSessionStorage,
    autoRefreshToken: true,
    persistSession: true,
    // Native handles deep-link callbacks manually via `createSessionFromUrl`;
    // the SDK's URL detector is only safe in browsers, where it parses
    // window.location for PKCE / implicit flows.
    detectSessionInUrl: Platform.OS === 'web',
    // PKCE is the modern, secure flow and is REQUIRED for native OAuth.
    // Magic-link callbacks also become `?code=` URLs we exchange in
    // `createSessionFromUrl`.
    flowType: 'pkce',
  },
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
});

// Pause/resume token auto-refresh with app lifecycle on native. The supabase
// background timer cannot tick reliably when the JS bridge is asleep, so we
// stop it when backgrounded and restart on foreground.
//
// Hold the subscription in module scope (mirrors the pattern in
// `~/lib/query-client.ts`). RN's `AppState.addEventListener` returns an
// `EmitterSubscription` with a `.remove()` method — we don't currently
// dispose, but dropping the return value entirely makes a future HMR cleanup
// impossible to wire without re-evaluating this module first.
if (Platform.OS !== 'web') {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const appStateSub = AppState.addEventListener('change', (state) => {
    if (state === 'active') {
      supabase.auth.startAutoRefresh();
    } else {
      supabase.auth.stopAutoRefresh();
    }
  });
}
