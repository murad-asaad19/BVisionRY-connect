import { useEffect, useState } from 'react';
import { Alert } from 'react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import * as Linking from 'expo-linking';
import i18n from 'i18next';
import { supabase } from '~/lib/supabase/client';
import {
  beginGithubOAuth,
  extractGithubIdentity,
  setGithubVerification,
} from '~/features/verification/services/verification.service';

// Stop listening for USER_UPDATED if the user never finishes the OAuth flow.
// 15 minutes accommodates users who pause mid-flow (2FA prompts, GitHub
// account switches, app-switch interruptions) without orphaning the listener.
const CONNECT_TIMEOUT_MS = 15 * 60 * 1000;

/**
 * Wires the GitHub identity-link flow.
 *
 * `linkIdentity()` resolves the moment the in-app browser opens, so the
 * mutation finishes long before the user has authorized on GitHub. We can't
 * gate the auth listener on `mutation.isPending` because that flag flips
 * false immediately. Instead, we set our own `awaiting` flag when the user
 * starts the flow and clear it when:
 *   - `USER_UPDATED` arrives and finalization succeeds, OR
 *   - the 15-minute window elapses (user abandoned or cancelled OAuth).
 *
 * The listener differentiates between "unrelated USER_UPDATED" (e.g. an email
 * change in another tab) and "GitHub link succeeded" by checking
 * `extractGithubIdentity()` — only the latter has the GitHub identity in
 * `user.identities`. Persistence failures surface as an Alert but keep
 * `awaiting` true so a retry on the next `USER_UPDATED` can finish the link.
 */
export function useConnectGithub() {
  const qc = useQueryClient();
  const [awaiting, setAwaiting] = useState(false);

  const mutation = useMutation({
    mutationFn: async () => {
      setAwaiting(true);
      const redirectTo = Linking.createURL('/auth/callback');
      await beginGithubOAuth(redirectTo);
    },
    onError: () => {
      setAwaiting(false);
    },
  });

  useEffect(() => {
    if (!awaiting) return;

    const { data: sub } = supabase.auth.onAuthStateChange(async (event) => {
      if (event !== 'USER_UPDATED') return;
      const { data, error } = await supabase.auth.getUser();
      if (error) return;
      const identity = extractGithubIdentity(data.user);
      // No github identity yet — this USER_UPDATED is unrelated (email change,
      // etc.). Stay subscribed and wait for the real link event.
      if (!identity) return;
      try {
        await setGithubVerification(identity.username, identity.id);
        await qc.invalidateQueries({ queryKey: ['profile'] });
        // Only clear `awaiting` on success. A persistence failure (network,
        // transient supabase error) keeps the listener subscribed so the next
        // USER_UPDATED can retry without the user re-opening the browser.
        setAwaiting(false);
      } catch (e) {
        Alert.alert(i18n.t('verification.connectFailed.title'), (e as Error).message);
      }
    });

    const timeout = setTimeout(() => setAwaiting(false), CONNECT_TIMEOUT_MS);

    return () => {
      sub.subscription.unsubscribe();
      clearTimeout(timeout);
    };
  }, [awaiting, qc]);

  return mutation;
}
