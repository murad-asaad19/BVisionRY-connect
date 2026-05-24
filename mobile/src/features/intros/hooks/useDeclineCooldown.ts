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
 * before they can send another intro to the same person. Prefer the explicit
 * `declined_at` stamp (added in 20260606080000); fall back to `updated_at`
 * for legacy declined rows where the column is NULL.
 *
 * The server enforces the same window in send_intro (P0001 / hint='cooldown'),
 * so this hook is purely an affordance to grey out the Send button up-front.
 */
export function useDeclineCooldown(targetUserId: string | undefined) {
  const { session } = useAuthSession();
  const myId = session?.user.id;
  return useQuery({
    queryKey: ['decline-cooldown', myId, targetUserId],
    enabled: !!myId && !!targetUserId,
    staleTime: 60_000,
    queryFn: async (): Promise<DeclineCooldown> => {
      // declined_at is not yet in generated types; select * and read it dynamically.
      const { data, error } = await supabase
        .from('intros')
        .select('*')
        .eq('sender_id', myId!)
        .eq('recipient_id', targetUserId!)
        .eq('state', 'declined')
        .order('updated_at', { ascending: false })
        .limit(1);
      if (error) throw new Error(error.message);
      const row = data?.[0] as
        | (Record<string, unknown> & { updated_at: string; declined_at?: string | null })
        | undefined;
      if (!row) return { active: false, availableAt: null };
      const baseIso = (row.declined_at ?? row.updated_at) as string;
      const declinedAt = new Date(baseIso).getTime();
      const availableAtMs = declinedAt + COOLDOWN_DAYS * DAY_MS;
      const active = Date.now() < availableAtMs;
      return {
        active,
        availableAt: active ? new Date(availableAtMs).toISOString() : null,
      };
    },
  });
}
