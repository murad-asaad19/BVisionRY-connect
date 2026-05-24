import { useQuery } from '@tanstack/react-query';
import { useAuthSession } from '~/features/auth/SessionContext';
import { supabase } from '~/lib/supabase/client';

/**
 * Count of intros currently delivered (unacted-on) for the signed-in user.
 * Powers the Inbox tab badge. Uses a `head + count: 'exact'` request so no
 * row payload is downloaded — only the count from the response header.
 */
export function useUnreadIntros() {
  const { session } = useAuthSession();
  const userId = session?.user.id;

  return useQuery({
    queryKey: ['intros', 'inbox-unread', userId],
    enabled: !!userId,
    staleTime: 30_000,
    queryFn: async () => {
      const { count, error } = await supabase
        .from('intros')
        .select('id', { count: 'exact', head: true })
        .eq('recipient_id', userId!)
        .eq('state', 'delivered');
      if (error) throw new Error(error.message);
      return count ?? 0;
    },
  });
}
