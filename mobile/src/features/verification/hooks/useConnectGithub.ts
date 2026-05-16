import { useMutation, useQueryClient } from '@tanstack/react-query';
import * as Linking from 'expo-linking';
import { supabase } from '~/lib/supabase/client';
import {
  beginGithubOAuth,
  extractGithubIdentity,
  setGithubVerification,
} from '~/features/verification/services/verification.service';

export function useConnectGithub() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const redirectTo = Linking.createURL('/auth/callback');
      await beginGithubOAuth(redirectTo);
      // After the deep-link callback resolves the session, the caller
      // refetches `auth.getUser()` and calls finishConnect.
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['profile'] });
    },
  });
}

/**
 * Called after the OAuth deep link returns and the supabase session is
 * refreshed. Extracts the GitHub identity from the current user and
 * persists it via set_github_verification.
 */
export async function finishGithubConnect(): Promise<void> {
  const { data, error } = await supabase.auth.getUser();
  if (error) throw new Error(error.message);
  const identity = extractGithubIdentity(data.user);
  if (!identity) throw new Error('GitHub identity not present on user');
  await setGithubVerification(identity.username, identity.id);
}
