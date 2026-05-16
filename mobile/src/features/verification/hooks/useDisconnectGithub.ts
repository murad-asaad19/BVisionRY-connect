import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import { clearGithubVerification } from '~/features/verification/services/verification.service';

export function useDisconnectGithub() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      // Unlink the GitHub identity from auth.users (best-effort)
      try {
        const { data } = await supabase.auth.getUserIdentities();
        const gh = data?.identities?.find((i) => i.provider === 'github');
        if (gh) {
          await supabase.auth.unlinkIdentity(gh);
        }
      } catch (e) {
        console.warn('[verification] unlinkIdentity failed', e);
      }
      await clearGithubVerification();
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['profile'] });
    },
  });
}
