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

export async function signUpWithPassword(email: string, password: string): Promise<void> {
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: { emailRedirectTo: authRedirectUri },
  });
  if (error) throw new Error(error.message);
}

export async function signInWithEmailPassword(email: string, password: string): Promise<void> {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);
}

/**
 * Sign in with either an email address or a public handle ("@username").
 * If the identifier doesn't contain "@", we resolve the handle to its
 * email via the `lookup_email_by_handle` RPC, then call signInWithPassword.
 */
export async function signInWithIdentifier(identifier: string, password: string): Promise<void> {
  const trimmed = identifier.trim();
  if (!trimmed) throw new Error('Email or username is required');
  if (!password) throw new Error('Password is required');

  let email = trimmed;
  if (!trimmed.includes('@')) {
    const { data, error } = await supabase.rpc('lookup_email_by_handle', {
      p_handle: trimmed.replace(/^@/, ''),
    });
    if (error) throw new Error(error.message);
    if (!data) throw new Error('No account found for that username');
    email = data as string;
  }

  await signInWithEmailPassword(email, password);
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
