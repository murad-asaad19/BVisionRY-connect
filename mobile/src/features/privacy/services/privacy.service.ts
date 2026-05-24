import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type ReportTargetType = Database['public']['Enums']['report_target_type'];
export type ReportReason = Database['public']['Enums']['report_reason'];
export type BlockedUserRow =
  Database['public']['Functions']['list_blocked_users']['Returns'][number];

export async function blockUser(target: string): Promise<void> {
  const { error } = await supabase.rpc('block_user', { p_target: target });
  if (error) throw new Error(error.message);
}

export async function unblockUser(target: string): Promise<void> {
  const { error } = await supabase.rpc('unblock_user', { p_target: target });
  if (error) throw new Error(error.message);
}

export async function listBlockedUsers(): Promise<BlockedUserRow[]> {
  const { data, error } = await supabase.rpc('list_blocked_users');
  if (error) throw new Error(error.message);
  return (data ?? []) as BlockedUserRow[];
}

export async function reportTarget(
  targetType: ReportTargetType,
  targetId: string,
  reason: ReportReason,
  note: string | null
): Promise<void> {
  // The SQL function accepts `p_note text` (nullable, see slice9_privacy.sql)
  // but types.gen.ts surfaces it as `string`. Narrow the cast to just that
  // field so the surrounding args stay strictly typed.
  const { error } = await supabase.rpc('report_target', {
    p_target_type: targetType,
    p_target_id: targetId,
    p_reason: reason,
    p_note: note as unknown as string,
  });
  if (error) throw new Error(error.message);
}
