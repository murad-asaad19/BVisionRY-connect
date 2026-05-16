jest.mock('~/lib/supabase/client', () => ({
  supabase: { from: jest.fn(), rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  deleteMessage,
  editMessage,
  fetchConversationsPage,
  fetchMessages,
  isConversationMuted,
  listConversationUnread,
  markConversationRead,
  muteConversation,
  sendMessage,
  unmuteConversation,
} from '~/features/chat/services/chat.service';

describe('chat.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('fetchConversationsPage', () => {
    it('filters by participant a or b, paginated by updated_at cursor desc', async () => {
      const rows = [
        {
          id: 'c1',
          participant_a_id: 'me',
          participant_b_id: 'u2',
          updated_at: '2026-05-14T00:00:00Z',
        },
      ];
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const lt = jest.fn().mockReturnValue({ order });
      const or = jest.fn().mockReturnValue({ lt });
      const select = jest.fn().mockReturnValue({ or });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchConversationsPage({
        userId: 'me',
        cursor: '2026-05-15T00:00:00Z',
        pageSize: 20,
      });
      expect(supabase.from).toHaveBeenCalledWith('conversations');
      expect(or).toHaveBeenCalledWith('participant_a_id.eq.me,participant_b_id.eq.me');
      expect(lt).toHaveBeenCalledWith('updated_at', '2026-05-15T00:00:00Z');
      expect(order).toHaveBeenCalledWith('updated_at', { ascending: false });
      expect(limit).toHaveBeenCalledWith(20);
      expect(result.rows).toEqual(rows);
      expect(result.nextCursor).toBeNull();
    });

    it('returns nextCursor on full page', async () => {
      const rows = Array.from({ length: 20 }).map((_, i) => ({
        id: `c${i}`,
        participant_a_id: 'me',
        participant_b_id: `u${i}`,
        updated_at: `2026-05-${String(10 + i).padStart(2, '0')}T00:00:00Z`,
      }));
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const lt = jest.fn().mockReturnValue({ order });
      const or = jest.fn().mockReturnValue({ lt });
      const select = jest.fn().mockReturnValue({ or });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchConversationsPage({
        userId: 'me',
        cursor: '9999-12-31T00:00:00Z',
        pageSize: 20,
      });
      expect(result.rows.length).toBe(20);
      expect(result.nextCursor).toBe(rows[rows.length - 1]!.updated_at);
    });
  });

  describe('fetchMessages', () => {
    it('selects latest 50 messages for a conversation ordered by created_at asc', async () => {
      const rows = [{ id: 'm1', body: 'hi' }];
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const eq = jest.fn().mockReturnValue({ order });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchMessages('c1');
      expect(supabase.from).toHaveBeenCalledWith('messages');
      expect(eq).toHaveBeenCalledWith('conversation_id', 'c1');
      expect(order).toHaveBeenCalledWith('created_at', { ascending: true });
      expect(limit).toHaveBeenCalledWith(50);
      expect(result).toEqual(rows);
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
      });
      expect(result).toEqual(row);
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
