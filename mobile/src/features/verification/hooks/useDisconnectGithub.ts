import { Alert } from 'react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import i18n from 'i18next';
import { supabase } from '~/lib/supabase/client';
import { clearGithubVerification } from '~/features/verification/services/verification.service';

export function useDisconnectGithub() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      // Look up the linked GitHub identity. If it's already absent, that's a
      // success path: we still need to clear the verification badge so the UI
      // matches reality (e.g. identity was revoked outside the app).
      const { data, error: listError } = await supabase.auth.getUserIdentities();
      if (listError) throw new Error(listError.message);
      const gh = data?.identities?.find((i) => i.provider === 'github');

      if (gh) {
        const { error: unlinkError } = await supabase.auth.unlinkIdentity(gh);
        if (unlinkError) {
          // Real unlink failure: the identity is still attached, so clearing
          // verification would lie to the UI. Surface a localized error and
          // bail before touching the badge.
          Alert.alert(
            i18n.t('verification.unlinkFailed.title'),
            i18n.t('verification.unlinkFailed.body')
          );
          throw new Error(unlinkError.message);
        }
      }

      // Either we unlinked successfully or the identity was already absent —
      // both cases mean the verification badge should come off.
      await clearGithubVerification();
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['profile'] });
    },
  });
}
