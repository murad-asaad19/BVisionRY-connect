import { supabase } from '~/lib/supabase/client';

type NotifyPatch = {
  notify_intro?: boolean;
  notify_message?: boolean;
  notify_meeting?: boolean;
};

export async function updateNotificationPrefs(userId: string, patch: NotifyPatch): Promise<void> {
  const { error } = await supabase.from('profiles').update(patch).eq('id', userId);
  if (error) throw new Error(error.message);
}

export async function exportMyData(): Promise<unknown> {
  const { data, error } = await supabase.rpc('export_my_data');
  if (error) throw new Error(error.message);
  return data;
}

export async function deleteMyAccount(): Promise<void> {
  const { error } = await supabase.functions.invoke('delete-account', { method: 'POST' });
  if (error) throw new Error(error.message);
  await supabase.auth.signOut();
}
