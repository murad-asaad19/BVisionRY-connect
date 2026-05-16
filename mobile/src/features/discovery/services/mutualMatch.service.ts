import { supabase } from '~/lib/supabase/client';

export async function isMutualMatch(otherUserId: string): Promise<boolean> {
  const { data, error } = await supabase.rpc('is_mutual_match', { p_other: otherUserId });
  if (error) throw new Error(error.message);
  return !!data;
}
