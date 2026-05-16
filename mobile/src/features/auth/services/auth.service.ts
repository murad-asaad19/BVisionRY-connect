import { makeRedirectUri } from 'expo-auth-session';
import { supabase } from '~/lib/supabase/client';

export const authRedirectUri = makeRedirectUri({ scheme: 'connect-mobile', path: 'auth' });

export async function sendMagicLink(email: string): Promise<void> {
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { emailRedirectTo: authRedirectUri },
  });
  if (error) throw new Error(error.message);
}

function parseHashParams(url: string): Record<string, string> {
  const hashIndex = url.indexOf('#');
  if (hashIndex === -1) return {};
  const fragment = url.slice(hashIndex + 1);
  return Object.fromEntries(
    fragment.split('&').map((pair) => {
      const [k, v] = pair.split('=');
      return [decodeURIComponent(k ?? ''), decodeURIComponent(v ?? '')];
    })
  );
}

export async function createSessionFromUrl(url: string) {
  const params = parseHashParams(url);
  const access_token = params.access_token;
  const refresh_token = params.refresh_token;
  if (!access_token || !refresh_token) return null;
  const { data, error } = await supabase.auth.setSession({ access_token, refresh_token });
  if (error) throw new Error(error.message);
  return data.session;
}

export async function signOut(): Promise<void> {
  const { error } = await supabase.auth.signOut();
  if (error) throw new Error(error.message);
}
