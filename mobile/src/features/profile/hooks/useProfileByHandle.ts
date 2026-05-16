import { useQuery } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

type Profile = Database['public']['Tables']['profiles']['Row'];

export async function fetchProfileByHandle(handle: string): Promise<Profile | null> {
  const { data, error } = await supabase.from('profiles').select('*').eq('handle', handle).single();

  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(error.message);
  }
  return data;
}

export function useProfileByHandle(handle: string) {
  return useQuery({
    queryKey: ['profile-by-handle', handle],
    queryFn: () => fetchProfileByHandle(handle),
    enabled: !!handle,
    staleTime: 60_000,
  });
}
