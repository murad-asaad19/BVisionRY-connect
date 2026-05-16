import { createClient } from '@supabase/supabase-js';
import { env } from '~/lib/env';

const anonClient = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
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
