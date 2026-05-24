jest.mock('~/lib/supabase/client', () => ({
  supabase: { from: jest.fn(), rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  deleteMessage,
  editMessage,
  fetchConversationsOverview,
  fetchMessagesPage,
  isConversationMuted,
  listConversationUnread,
  markConversationRead,
  muteConversation,
  sendMessage,
  unmuteConversation,
} from '~/features/chat/services/chat.service';

describe('chat.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('fetchConversationsOverview', () => {
    it('calls the list_conversation_overview RPC with the caller id', async () => {
      const rows = [
        {
          conversation_id: 'c1',
          peer_id: 'u2',
          peer_name: 'Bea',
          peer_handle: 'bea',
          peer_photo_url: null,
          last_message_body: 'hi',
          last_message_kind: 'text',
          last_message_at: '2026-05-14T00:00:00Z',
          unread_count: 0,
          is_muted: false,
        },
      ];
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: rows, error: null });
      const result = await fetchConversationsOverview('me');
      expect(supabase.rpc).toHaveBeenCalledWith('list_conversation_overview', { p_user_id: 'me' });
      expect(result).toEqual(rows);
    });

    it('throws on RPC error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'forbidden' },
      });
      await expect(fetchConversationsOverview('me')).rejects.toThrow('forbidden');
    });
  });

  describe('fetchMessagesPage', () => {
    it('selects the freshest page (DESC by created_at) without a cursor', async () => {
      const rows = [{ id: 'm1', body: 'hi', created_at: '2026-05-16T00:00:00Z' }];
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const eq = jest.fn().mockReturnValue({ order });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchMessagesPage({ conversationId: 'c1', before: null });
      expect(supabase.from).toHaveBeenCalledWith('messages');
      expect(eq).toHaveBeenCalledWith('conversation_id', 'c1');
      expect(order).toHaveBeenCalledWith('created_at', { ascending: false });
      expect(result.rows).toEqual(rows);
      expect(result.nextCursor).toBeNull();
    });

    it('appends an lt() cursor filter on subsequent pages and reports nextCursor on full page', async () => {
      const rows = Array.from({ length: 30 }).map((_, i) => ({
        id: `m${i}`,
        body: `b${i}`,
        created_at: `2026-05-${String(10 + i).padStart(2, '0')}T00:00:00Z`,
      }));
      const ltMock = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const limit = jest.fn().mockReturnValue({ lt: ltMock });
      const order = jest.fn().mockReturnValue({ limit });
      const eq = jest.fn().mockReturnValue({ order });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchMessagesPage({
        conversationId: 'c1',
        before: '2026-06-01T00:00:00Z',
        pageSize: 30,
      });
      expect(ltMock).toHaveBeenCalledWith('created_at', '2026-06-01T00:00:00Z');
      expect(result.nextCursor).toBe(rows[rows.length - 1]!.created_at);
    });
  });

  describe('sendMessage', () => {
    it('inserts a message with sender_id, conversation_id, body and returns the row', async () => {
      const row = { id: 'm1', body: 'hi', sender_id: 'me', conversation_id: 'c1' };
      const single = jest.fn().mockResolvedValueOnce({ data: row, error: null });
      const select = jest.fn().mockReturnValue({ single });
      const insert = jest.fn().mockReturnValue({ select });
      (supabase.from as jest.Mock).mockReturnValue({ insert });

      const result = await sendMessage({ conversationId: 'c1', senderId: 'me', body: 'hi' });
      expect(supabase.from).toHaveBeenCalledWith('messages');
      expect(insert).toHaveBeenCalledWith({
        conversation_id: 'c1',
        sender_id: 'me',
        body: 'hi',
        kind: 'text',
      });
      expect(result).toEqual(row);
    });

    it('forwards the client-supplied id when provided', async () => {
      const row = { id: 'abc', body: 'hi', sender_id: 'me', conversation_id: 'c1' };
      const single = jest.fn().mockResolvedValueOnce({ data: row, error: null });
      const select = jest.fn().mockReturnValue({ single });
      const insert = jest.fn().mockReturnValue({ select });
      (supabase.from as jest.Mock).mockReturnValue({ insert });

      await sendMessage({ id: 'abc', conversationId: 'c1', senderId: 'me', body: 'hi' });
      expect(insert).toHaveBeenCalledWith({
        id: 'abc',
        conversation_id: 'c1',
        sender_id: 'me',
        body: 'hi',
        kind: 'text',
      });
    });

    it('throws on insert error', async () => {
      const single = jest.fn().mockResolvedValueOnce({ data: null, error: { message: 'denied' } });
      const select = jest.fn().mockReturnValue({ single });
      const insert = jest.fn().mockReturnValue({ select });
      (supabase.from as jest.Mock).mockReturnValue({ insert });
      await expect(
        sendMessage({ conversationId: 'c1', senderId: 'me', body: 'hi' })
      ).rejects.toThrow('denied');
    });
  });

  describe('markConversationRead', () => {
    it('calls mark_conversation_read RPC with conversation id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await markConversationRead('c1');
      expect(supabase.rpc).toHaveBeenCalledWith('mark_conversation_read', {
        p_conversation_id: 'c1',
      });
    });
  });

  describe('muteConversation / unmuteConversation', () => {
    it('calls mute_conversation and unmute_conversation RPCs', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await muteConversation('c1');
      expect(supabase.rpc).toHaveBeenLastCalledWith('mute_conversation', {
        p_conversation_id: 'c1',
      });

      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await unmuteConversation('c1');
      expect(supabase.rpc).toHaveBeenLastCalledWith('unmute_conversation', {
        p_conversation_id: 'c1',
      });
    });
  });

  describe('listConversationUnread', () => {
    it('returns RPC rows as unread counts', async () => {
      const rows = [{ conversation_id: 'c1', unread_count: 3 }];
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: rows, error: null });
      const result = await listConversationUnread();
      expect(supabase.rpc).toHaveBeenCalledWith('list_conversation_unread');
      expect(result).toEqual(rows);
    });
  });

  describe('isConversationMuted', () => {
    it('returns true when a row exists for (user, conversation)', async () => {
      const maybeSingle = jest.fn().mockResolvedValueOnce({
        data: { conversation_id: 'c1' },
        error: null,
      });
      const eq2 = jest.fn().mockReturnValue({ maybeSingle });
      const eq1 = jest.fn().mockReturnValue({ eq: eq2 });
      const select = jest.fn().mockReturnValue({ eq: eq1 });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const muted = await isConversationMuted({ userId: 'u', conversationId: 'c1' });
      expect(supabase.from).toHaveBeenCalledWith('conversation_mutes');
      expect(eq1).toHaveBeenCalledWith('user_id', 'u');
      expect(eq2).toHaveBeenCalledWith('conversation_id', 'c1');
      expect(muted).toBe(true);
    });

    it('returns false when no row exists', async () => {
      const maybeSingle = jest.fn().mockResolvedValueOnce({ data: null, error: null });
      const eq2 = jest.fn().mockReturnValue({ maybeSingle });
      const eq1 = jest.fn().mockReturnValue({ eq: eq2 });
      const select = jest.fn().mockReturnValue({ eq: eq1 });
      (supabase.from as jest.Mock).mockReturnValue({ select });
      const muted = await isConversationMuted({ userId: 'u', conversationId: 'c1' });
      expect(muted).toBe(false);
    });
  });

  describe('editMessage', () => {
    it('calls edit_message RPC and returns the row', async () => {
      const row = { id: 'm1', body: 'new', edited_at: '2026-05-16T00:00:00Z' };
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: row, error: null });
      const result = await editMessage({ id: 'm1', body: 'new' });
      expect(supabase.rpc).toHaveBeenCalledWith('edit_message', { p_id: 'm1', p_body: 'new' });
      expect(result).toEqual(row);
    });

    it('throws on edit RPC error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'edit window expired' },
      });
      await expect(editMessage({ id: 'm1', body: 'new' })).rejects.toThrow('edit window expired');
    });
  });

  describe('deleteMessage', () => {
    it('calls delete_message RPC and returns the tombstoned row', async () => {
      const row = { id: 'm1', body: null, deleted_at: '2026-05-16T00:00:00Z' };
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: row, error: null });
      const result = await deleteMessage('m1');
      expect(supabase.rpc).toHaveBeenCalledWith('delete_message', { p_id: 'm1' });
      expect(result).toEqual(row);
    });
  });
});
