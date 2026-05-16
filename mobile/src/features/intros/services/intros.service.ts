import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type IntroRow = Database['public']['Tables']['intros']['Row'];
export type IntroState = Database['public']['Enums']['intro_state'];

const PAGE_SIZE = 20;

export async function sendIntro(params: { recipientId: string; note: string }): Promise<IntroRow> {
  const { data, error } = await supabase.rpc('send_intro', {
    p_recipient_id: params.recipientId,
    p_note: params.note,
  });
  if (error) throw new Error(error.message);
  return data as IntroRow;
}

export async function acceptIntro(introId: string): Promise<IntroRow> {
  const { data, error } = await supabase.rpc('accept_intro', { p_intro_id: introId });
  if (error) throw new Error(error.message);
  return data as IntroRow;
}

export async function declineIntro(introId: string): Promise<IntroRow> {
  const { data, error } = await supabase.rpc('decline_intro', { p_intro_id: introId });
  if (error) throw new Error(error.message);
  return data as IntroRow;
}

export async function fetchInboxPage(params: {
  userId: string;
  cursor: string;
  pageSize?: number;
}): Promise<{ rows: IntroRow[]; nextCursor: string | null }> {
  const limit = params.pageSize ?? PAGE_SIZE;
  const { data, error } = await supabase
    .from('intros')
    .select('*')
    .eq('recipient_id', params.userId)
    .in('state', ['delivered', 'accepted'])
    .gt('expires_at', new Date().toISOString())
    .lt('created_at', params.cursor)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as IntroRow[];
  const nextCursor = rows.length === limit ? rows[rows.length - 1]!.created_at : null;
  return { rows, nextCursor };
}

export async function fetchSentPage(params: {
  userId: string;
  cursor: string;
  pageSize?: number;
}): Promise<{ rows: IntroRow[]; nextCursor: string | null }> {
  const limit = params.pageSize ?? PAGE_SIZE;
  const { data, error } = await supabase
    .from('intros')
    .select('*')
    .eq('sender_id', params.userId)
    .lt('created_at', params.cursor)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as IntroRow[];
  const nextCursor = rows.length === limit ? rows[rows.length - 1]!.created_at : null;
  return { rows, nextCursor };
}

export async function fetchIntroById(id: string): Promise<IntroRow | null> {
  const { data, error } = await supabase.from('intros').select('*').eq('id', id).single();
  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(error.message);
  }
  return data;
}
