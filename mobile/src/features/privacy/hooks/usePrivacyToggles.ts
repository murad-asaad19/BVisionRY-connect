import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';

type ProfileToggles = {
  private_mode?: boolean;
  read_receipts_enabled?: boolean;
  public_investor_page?: boolean;
};

/**
 * Optimistically patch the cached profile row so the bound `<Switch>` flips
 * instantly. Returns the previous snapshot for `onError` rollback.
 *
 * We patch every variant of the profile cache key (with and without userId
 * suffix) so both `useCurrentUserProfile(['profile', userId])` and any
 * legacy `['profile']` consumers stay in sync.
 */
async function applyOptimisticProfilePatch(
  qc: ReturnType<typeof useQueryClient>,
  patch: ProfileToggles
): Promise<{ snap: [readonly unknown[], unknown][] }> {
  await qc.cancelQueries({ queryKey: ['profile'] });
  const snap = qc.getQueriesData({ queryKey: ['profile'] });
  qc.setQueriesData({ queryKey: ['profile'] }, (old: unknown) => {
    if (!old || typeof old !== 'object') return old;
    return { ...(old as object), ...patch };
  });
  return { snap };
}

function rollback(
  qc: ReturnType<typeof useQueryClient>,
  ctx: { snap: [readonly unknown[], unknown][] } | undefined
) {
  if (!ctx) return;
  ctx.snap.forEach(([key, value]) => qc.setQueryData(key, value));
}

export function useSetPrivateMode() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (value: boolean) => {
      const { error } = await supabase.rpc('set_private_mode', { p_value: value });
      if (error) throw new Error(error.message);
    },
    onMutate: (value) => applyOptimisticProfilePatch(qc, { private_mode: value }),
    onError: (_err, _vars, ctx) => rollback(qc, ctx),
    onSettled: () => {
      qc.invalidateQueries({ queryKey: ['profile'] });
      qc.invalidateQueries({ queryKey: ['daily-matches'] });
      qc.invalidateQueries({ queryKey: ['feed'] });
    },
  });
}

export function useUpdateProfileToggle(userId: string | undefined) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (patch: {
      read_receipts_enabled?: boolean;
      public_investor_page?: boolean;
    }) => {
      if (!userId) throw new Error('not signed in');
      const { error } = await supabase.from('profiles').update(patch).eq('id', userId);
      if (error) throw new Error(error.message);
    },
    onMutate: (patch) => applyOptimisticProfilePatch(qc, patch),
    onError: (_err, _vars, ctx) => rollback(qc, ctx),
    onSettled: () => qc.invalidateQueries({ queryKey: ['profile'] }),
  });
}
