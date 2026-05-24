import { supabase } from '~/lib/supabase/client';
import type { User } from '@supabase/supabase-js';

export type GithubIdentity = { username: string; id: number };

export async function setGithubVerification(username: string, id: number): Promise<void> {
  const { error } = await supabase.rpc('set_github_verification', {
    p_github_username: username,
    p_github_id: id,
  });
  if (error) throw new Error(error.message);
}

export async function clearGithubVerification(): Promise<void> {
  const { error } = await supabase.rpc('clear_github_verification');
  if (error) throw new Error(error.message);
}

export async function beginGithubOAuth(redirectTo: string): Promise<void> {
  const { error } = await supabase.auth.linkIdentity({
    provider: 'github',
    options: { redirectTo },
  });
  if (error) throw new Error(error.message);
}

export function extractGithubIdentity(user: User | null): GithubIdentity | null {
  if (!user?.identities) return null;
  const gh = user.identities.find((i) => i.provider === 'github');
  if (!gh) return null;
  const data = gh.identity_data as { user_name?: string; provider_id?: string } | undefined;
  if (!data?.user_name || !data?.provider_id) return null;
  const id = Number(data.provider_id);
  if (!Number.isFinite(id) || id <= 0) return null;
  return { username: data.user_name, id };
}
