import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type Profile = Database['public']['Tables']['profiles']['Row'];
export type ProfileUpdate = Database['public']['Tables']['profiles']['Update'];

export async function checkHandleAvailable(handle: string): Promise<boolean> {
  const { data, error } = await supabase.rpc('check_handle_available', { p_handle: handle });
  if (error) throw new Error(error.message);
  return data === true;
}

export async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase.from('profiles').select('*').eq('id', userId).single();
  if (error) throw new Error(error.message);
  return data;
}

export async function updateProfile(userId: string, patch: ProfileUpdate): Promise<Profile> {
  const { data, error } = await supabase
    .from('profiles')
    .update(patch)
    .eq('id', userId)
    .select()
    .single();
  if (error) throw new Error(error.message);
  return data;
}
