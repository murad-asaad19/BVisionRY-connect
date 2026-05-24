import { useQuery } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

type Profile = Database['public']['Tables']['profiles']['Row'];

export async function fetchProfileByHandle(handle: string): Promise<Profile | null> {
  // Handles are stored lowercase in the database. Forcing both the queryKey
  // and the query to the same casing keeps `/p/Ahmad` and `/p/ahmad` from
  // hitting two distinct cache entries (and from missing on the second URL).
  const normalized = handle.toLowerCase();
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('handle', normalized)
    .single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(error.message);
  }
  return data;
}

export function useProfileByHandle(handle: string) {
  const normalized = handle.toLowerCase();
  return useQuery({
    queryKey: ['profile-by-handle', normalized],
    queryFn: () => fetchProfileByHandle(normalized),
    enabled: !!normalized,
    staleTime: 60_000,
  });
}
