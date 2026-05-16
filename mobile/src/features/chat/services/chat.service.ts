import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type ConversationRow = Database['public']['Tables']['conversations']['Row'];
export type MessageRow = Database['public']['Tables']['messages']['Row'];

const PAGE_SIZE = 20;

export async function fetchConversationsPage(params: {
  userId: string;
  cursor: string;
  pageSize?: number;
}): Promise<{ rows: ConversationRow[]; nextCursor: string | null }> {
  const limit = params.pageSize ?? PAGE_SIZE;
  const { data, error } = await supabase
    .from('conversations')
    .select('*')
    .or(`participant_a_id.eq.${params.userId},participant_b_id.eq.${params.userId}`)
    .lt('updated_at', params.cursor)
    .order('updated_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as ConversationRow[];
  const nextCursor = rows.length === limit ? rows[rows.length - 1]!.updated_at : null;
  return { rows, nextCursor };
}

export async function fetchMessages(conversationId: string): Promise<MessageRow[]> {
  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })
    .limit(50);
  if (error) throw new Error(error.message);
  return data ?? [];
}

export async function sendMessage(params: {
  conversationId: string;
  senderId: string;
  body: string;
}): Promise<MessageRow> {
  const { data, error } = await supabase
    .from('messages')
    .insert({
      conversation_id: params.conversationId,
      sender_id: params.senderId,
      body: params.body,
    })
    .select()
    .single();
  if (error) throw new Error(error.message);
  return data;
}

export async function markConversationRead(conversationId: string): Promise<void> {
  const { error } = await supabase.rpc('mark_conversation_read', {
    p_conversation_id: conversationId,
  });
  if (error) throw new Error(error.message);
}

export async function muteConversation(conversationId: string): Promise<void> {
  const { error } = await supabase.rpc('mute_conversation', {
    p_conversation_id: conversationId,
  });
  if (error) throw new Error(error.message);
}

export async function unmuteConversation(conversationId: string): Promise<void> {
  const { error } = await supabase.rpc('unmute_conversation', {
    p_conversation_id: conversationId,
  });
  if (error) throw new Error(error.message);
}

export type ConversationUnread = { conversation_id: string; unread_count: number };

export async function listConversationUnread(): Promise<ConversationUnread[]> {
  const { data, error } = await supabase.rpc('list_conversation_unread');
  if (error) throw new Error(error.message);
  return (data ?? []) as ConversationUnread[];
}

export async function isConversationMuted(params: {
  userId: string;
  conversationId: string;
}): Promise<boolean> {
  const { data, error } = await supabase
    .from('conversation_mutes')
    .select('conversation_id')
    .eq('user_id', params.userId)
    .eq('conversation_id', params.conversationId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data !== null;
}

export async function editMessage(params: { id: string; body: string }): Promise<MessageRow> {
  const { data, error } = await supabase.rpc('edit_message', {
    p_id: params.id,
    p_body: params.body,
  });
  if (error) throw new Error(error.message);
  return data as MessageRow;
}

export async function deleteMessage(id: string): Promise<MessageRow> {
  const { data, error } = await supabase.rpc('delete_message', { p_id: id });
  if (error) throw new Error(error.message);
  return data as MessageRow;
}
