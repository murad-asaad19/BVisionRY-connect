import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';

export function useSetPrivateMode() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (value: boolean) => {
      const { error } = await supabase.rpc('set_private_mode', { p_value: value });
      if (error) throw new Error(error.message);
    },
    onSuccess: () => {
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
    onSuccess: () => qc.invalidateQueries({ queryKey: ['profile'] }),
  });
}
