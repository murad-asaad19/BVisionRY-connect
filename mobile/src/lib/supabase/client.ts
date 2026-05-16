import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';
import { env } from '~/lib/env';
import { supabaseSessionStorage } from '~/lib/supabase/sessionStorage';
import type { Database } from './types.gen';

export const supabase = createClient<Database>(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
  auth: {
    storage: supabaseSessionStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
