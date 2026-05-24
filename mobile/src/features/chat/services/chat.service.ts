import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type ConversationRow = Database['public']['Tables']['conversations']['Row'];
export type MessageRow = Database['public']['Tables']['messages']['Row'];
export type MessageKind = Database['public']['Enums']['message_kind'];

const MESSAGES_PAGE_SIZE = 30;

/**
 * One-shot overview for the chats list. Backed by SQL function
 * `list_conversation_overview(p_user_id uuid default auth.uid())` in
 * migration 20260606070000_chat_fixes.sql. The RPC is not yet in
 * types.gen.ts — cast through `unknown` until the regen.
 *
 * Returns ALL of the caller's conversations ordered last_message_at DESC.
 * Per-user volume is bounded (network is who they've connected with), so
 * no server-side pagination is necessary — the client can page through
 * the cached array in `useConversations`.
 */
export type ConversationOverviewRow = {
  conversation_id: string;
  peer_id: string | null;
  peer_name: string | null;
  peer_handle: string | null;
  peer_photo_url: string | null;
  last_message_body: string | null;
  last_message_kind: MessageKind | null;
  last_message_at: string | null;
  unread_count: number;
  is_muted: boolean;
};

export async function fetchConversationsOverview(
  userId: string
): Promise<ConversationOverviewRow[]> {
  const { data, error } = await (
    supabase.rpc as unknown as (
      fn: 'list_conversation_overview',
      args: { p_user_id: string }
    ) => Promise<{ data: ConversationOverviewRow[] | null; error: { message: string } | null }>
  )('list_conversation_overview', { p_user_id: userId });
  if (error) throw new Error(error.message);
  return (data ?? []) as ConversationOverviewRow[];
}

/**
 * Cursor-paginated message fetch. Returns DESC by created_at so the client
 * can render inside an `inverted` FlatList: index 0 = newest = visual
 * bottom. `before` is the oldest cached message's `created_at` (use `null`
 * for the first page).
 */
export async function fetchMessagesPage(params: {
  conversationId: string;
  before: string | null;
  pageSize?: number;
}): Promise<{ rows: MessageRow[]; nextCursor: string | null }> {
  const limit = params.pageSize ?? MESSAGES_PAGE_SIZE;
  let q = supabase
    .from('messages')
    .select('*')
    .eq('conversation_id', params.conversationId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (params.before) q = q.lt('created_at', params.before);
  const { data, error } = await q;
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as MessageRow[];
  const nextCursor = rows.length === limit ? rows[rows.length - 1]!.created_at : null;
  return { rows, nextCursor };
}

/**
 * Inserts a text message. When `id` is provided, the client generates the
 * UUID so the optimistic temp row's id == the eventually-arriving server +
 * realtime row id, making dedup-by-id straightforward.
 *
 * `kind: 'text'` is sent explicitly as defence-in-depth against the RLS
 * policy that pins this code path to text messages (other kinds go through
 * dedicated RPCs or server-side inserts).
 */
export async function sendMessage(params: {
  id?: string;
  conversationId: string;
  senderId: string;
  body: string;
}): Promise<MessageRow> {
  const insertRow: {
    id?: string;
    conversation_id: string;
    sender_id: string;
    body: string;
    kind: MessageKind;
  } = {
    conversation_id: params.conversationId,
    sender_id: params.senderId,
    body: params.body,
    kind: 'text',
  };
  if (params.id) insertRow.id = params.id;
  const { data, error } = await supabase
    .from('messages')
    .insert(insertRow)
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
