import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type ConnectionRow = Database['public']['Functions']['list_connections']['Returns'][number];

export async function listConnections(): Promise<ConnectionRow[]> {
  const { data, error } = await supabase.rpc('list_connections');
  if (error) throw new Error(error.message);
  return (data ?? []) as ConnectionRow[];
}
