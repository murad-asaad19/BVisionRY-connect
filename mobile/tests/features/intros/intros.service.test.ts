jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn(), from: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  sendIntro,
  acceptIntro,
  declineIntro,
  fetchInboxPage,
  fetchSentPage,
  fetchIntroById,
} from '~/features/intros/services/intros.service';

describe('intros.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('sendIntro', () => {
    it('calls send_intro RPC with recipientId and note', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: { id: 'i1' }, error: null });
      await sendIntro({ recipientId: 'u2', note: 'x'.repeat(100) });
      expect(supabase.rpc).toHaveBeenCalledWith('send_intro', {
        p_recipient_id: 'u2',
        p_note: 'x'.repeat(100),
      });
    });
    it('throws on RPC error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: { message: 'oops' } });
      await expect(sendIntro({ recipientId: 'u2', note: 'x'.repeat(100) })).rejects.toThrow('oops');
    });
  });

  describe('acceptIntro', () => {
    it('calls accept_intro RPC', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: { id: 'i1', state: 'accepted' },
        error: null,
      });
      const result = await acceptIntro('i1');
      expect(supabase.rpc).toHaveBeenCalledWith('accept_intro', { p_intro_id: 'i1' });
      expect(result.state).toBe('accepted');
    });
  });

  describe('declineIntro', () => {
    it('calls decline_intro RPC', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: { id: 'i1', state: 'declined' },
        error: null,
      });
      const result = await declineIntro('i1');
      expect(supabase.rpc).toHaveBeenCalledWith('decline_intro', { p_intro_id: 'i1' });
      expect(result.state).toBe('declined');
    });
  });

  describe('fetchInboxPage', () => {
    it('filters by recipient_id, allowed states, unexpired, paginated by created_at cursor desc', async () => {
      const rows = [{ id: 'i1', state: 'delivered', created_at: '2026-05-14T00:00:00Z' }];
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const lt = jest.fn().mockReturnValue({ order });
      const gt = jest.fn().mockReturnValue({ lt });
      const in_ = jest.fn().mockReturnValue({ gt });
      const eq = jest.fn().mockReturnValue({ in: in_ });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchInboxPage({
        userId: 'me',
        cursor: '2026-05-15T00:00:00Z',
        pageSize: 20,
      });

      expect(supabase.from).toHaveBeenCalledWith('intros');
      expect(eq).toHaveBeenCalledWith('recipient_id', 'me');
      expect(in_).toHaveBeenCalledWith('state', ['delivered', 'accepted', 'connected']);
      expect(gt).toHaveBeenCalledWith('expires_at', expect.any(String));
      expect(lt).toHaveBeenCalledWith('created_at', '2026-05-15T00:00:00Z');
      expect(order).toHaveBeenCalledWith('created_at', { ascending: false });
      expect(limit).toHaveBeenCalledWith(20);
      expect(result.rows).toEqual(rows);
      expect(result.nextCursor).toBeNull();
    });

    it('returns nextCursor on full page', async () => {
      const rows = Array.from({ length: 20 }).map((_, i) => ({
        id: `i${i}`,
        state: 'delivered',
        created_at: `2026-05-${String(10 + i).padStart(2, '0')}T00:00:00Z`,
      }));
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const lt = jest.fn().mockReturnValue({ order });
      const gt = jest.fn().mockReturnValue({ lt });
      const in_ = jest.fn().mockReturnValue({ gt });
      const eq = jest.fn().mockReturnValue({ in: in_ });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchInboxPage({
        userId: 'me',
        cursor: '9999-12-31T00:00:00Z',
        pageSize: 20,
      });
      expect(result.rows.length).toBe(20);
      expect(result.nextCursor).toBe(rows[rows.length - 1]!.created_at);
    });
  });

  describe('fetchSentPage', () => {
    it('filters by sender_id, paginated by created_at cursor desc', async () => {
      const rows = [{ id: 'i2', state: 'declined', created_at: '2026-05-14T00:00:00Z' }];
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const lt = jest.fn().mockReturnValue({ order });
      const eq = jest.fn().mockReturnValue({ lt });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchSentPage({
        userId: 'me',
        cursor: '2026-05-15T00:00:00Z',
        pageSize: 20,
      });
      expect(eq).toHaveBeenCalledWith('sender_id', 'me');
      expect(lt).toHaveBeenCalledWith('created_at', '2026-05-15T00:00:00Z');
      expect(order).toHaveBeenCalledWith('created_at', { ascending: false });
      expect(limit).toHaveBeenCalledWith(20);
      expect(result.rows).toEqual(rows);
      expect(result.nextCursor).toBeNull();
    });

    it('returns nextCursor on full page', async () => {
      const rows = Array.from({ length: 20 }).map((_, i) => ({
        id: `i${i}`,
        state: 'delivered',
        created_at: `2026-05-${String(10 + i).padStart(2, '0')}T00:00:00Z`,
      }));
      const limit = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
      const order = jest.fn().mockReturnValue({ limit });
      const lt = jest.fn().mockReturnValue({ order });
      const eq = jest.fn().mockReturnValue({ lt });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });

      const result = await fetchSentPage({
        userId: 'me',
        cursor: '9999-12-31T00:00:00Z',
        pageSize: 20,
      });
      expect(result.rows.length).toBe(20);
      expect(result.nextCursor).toBe(rows[rows.length - 1]!.created_at);
    });
  });

  describe('fetchIntroById', () => {
    it('selects single intro by id', async () => {
      const single = jest.fn().mockResolvedValueOnce({ data: { id: 'i1' }, error: null });
      const eq = jest.fn().mockReturnValue({ single });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });
      const result = await fetchIntroById('i1');
      expect(eq).toHaveBeenCalledWith('id', 'i1');
      expect(result?.id).toBe('i1');
    });
    it('returns null on PGRST116', async () => {
      const single = jest
        .fn()
        .mockResolvedValueOnce({ data: null, error: { code: 'PGRST116', message: 'nope' } });
      const eq = jest.fn().mockReturnValue({ single });
      const select = jest.fn().mockReturnValue({ eq });
      (supabase.from as jest.Mock).mockReturnValue({ select });
      expect(await fetchIntroById('i1')).toBeNull();
    });
  });
});
