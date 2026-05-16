import { useQuery } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import { useAuthSession } from '~/features/auth/SessionContext';

const COOLDOWN_DAYS = 30;
const DAY_MS = 24 * 60 * 60 * 1000;

export type DeclineCooldown = {
  active: boolean;
  /** ISO string of the date the sender can intro again (decline date + 30 days). */
  availableAt: string | null;
};

/**
 * §12 / I4: after a recipient declines, the sender sees a 30-day cooldown
 * before they can send another intro to the same person. We look for the
 * most recent declined intro between this user (as sender) and the target.
 */
export function useDeclineCooldown(targetUserId: string | undefined) {
  const { session } = useAuthSession();
  const myId = session?.user.id;
  return useQuery({
    queryKey: ['decline-cooldown', myId, targetUserId],
    enabled: !!myId && !!targetUserId,
    staleTime: 60_000,
    queryFn: async (): Promise<DeclineCooldown> => {
      const { data, error } = await supabase
        .from('intros')
        .select('updated_at')
        .eq('sender_id', myId!)
        .eq('recipient_id', targetUserId!)
        .eq('state', 'declined')
        .order('updated_at', { ascending: false })
        .limit(1);
      if (error) throw new Error(error.message);
      const row = data?.[0];
      if (!row) return { active: false, availableAt: null };
      const declinedAt = new Date(row.updated_at).getTime();
      const availableAtMs = declinedAt + COOLDOWN_DAYS * DAY_MS;
      const active = Date.now() < availableAtMs;
      return {
        active,
        availableAt: active ? new Date(availableAtMs).toISOString() : null,
      };
    },
  });
}
