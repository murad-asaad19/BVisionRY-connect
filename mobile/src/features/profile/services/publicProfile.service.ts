import { createClient } from '@supabase/supabase-js';
import { env } from '~/lib/env';

// Public-profile anon client. We intentionally instantiate a second supabase
// client because the public route must work for unauthenticated visitors —
// the main client carries a signed-in user's JWT when present, which would
// leak the caller's identity into the anon-only RPC.
//
// `storageKey` is set to a distinct value so GoTrueClient does not collide
// with the main client on the default `sb-{host}-auth-token` key (Supabase
// emits a "Multiple GoTrueClient instances detected" warning otherwise, and
// — on web — the two clients race to overwrite each other's session in
// localStorage). `persistSession: false` keeps the anon client stateless;
// `detectSessionInUrl: false` stops it from consuming magic-link fragments
// meant for the main client.
const anonClient = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
    storageKey: 'sb-public-profile-anon',
  },
});

export type PublicProfile = {
  id: string;
  handle: string;
  name: string | null;
  photo_url: string | null;
  headline: string | null;
  bio: string | null;
  primary_role: string | null;
  roles: string[];
  city: string | null;
  country: string | null;
  verified_github_username: string | null;
};

export async function fetchPublicProfile(handle: string): Promise<PublicProfile | null> {
  const { data, error } = await anonClient.rpc('get_public_profile', { p_handle: handle });
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as PublicProfile[];
  return rows[0] ?? null;
}
