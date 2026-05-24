jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  suggestWarmIntros,
  sendWarmRequest,
  forwardWarmIntro,
} from '~/features/intros/services/warmIntros.service';
import {
  IntroDuplicateError,
  IntroError,
  IntroRateLimitError,
} from '~/features/intros/services/intros.service';

describe('warmIntros.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('suggestWarmIntros', () => {
    it('calls suggest_warm_intros RPC with the default limit and maps rows to camelCase DTOs', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [
          {
            target_id: 't1',
            target_handle: 'bob',
            target_name: 'Bob',
            target_photo_url: null,
            target_primary_role: 'founder',
            target_goal_type: 'co_found',
            mutual_count: 2,
            top_mutual_id: 'm1',
            top_mutual_name: 'Alice',
            top_mutual_handle: 'alice',
          },
        ],
        error: null,
      });
      const result = await suggestWarmIntros();
      expect(supabase.rpc).toHaveBeenCalledWith('suggest_warm_intros', { p_limit: 10 });
      expect(result).toEqual([
        {
          targetId: 't1',
          targetHandle: 'bob',
          targetName: 'Bob',
          targetPhotoUrl: null,
          targetPrimaryRole: 'founder',
          targetGoalType: 'co_found',
          mutualCount: 2,
          topMutualId: 'm1',
          topMutualName: 'Alice',
          topMutualHandle: 'alice',
        },
      ]);
    });

    it('honours an explicit limit', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });
      await suggestWarmIntros(25);
      expect(supabase.rpc).toHaveBeenCalledWith('suggest_warm_intros', { p_limit: 25 });
    });

    it('returns [] when the RPC returns null data', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      expect(await suggestWarmIntros()).toEqual([]);
    });

    it('throws when the RPC returns an error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'unauthenticated' },
      });
      await expect(suggestWarmIntros()).rejects.toThrow('unauthenticated');
    });
  });

  describe('sendWarmRequest', () => {
    it('calls send_warm_request RPC with snake_case params and returns the new id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: 'new-intro-id', error: null });
      const id = await sendWarmRequest({
        mutualId: 'm1',
        targetId: 't1',
        note: 'x'.repeat(100),
      });
      expect(supabase.rpc).toHaveBeenCalledWith('send_warm_request', {
        p_mutual_id: 'm1',
        p_target_id: 't1',
        p_note: 'x'.repeat(100),
      });
      expect(id).toBe('new-intro-id');
    });

    it('maps 23505 errors onto IntroDuplicateError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '23505', message: 'warm request already pending' },
      });
      await expect(
        sendWarmRequest({ mutualId: 'm1', targetId: 't1', note: 'x'.repeat(100) })
      ).rejects.toBeInstanceOf(IntroDuplicateError);
    });

    it('maps daily-cap P0001 onto IntroRateLimitError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: 'P0001', message: 'daily cap reached' },
      });
      await expect(
        sendWarmRequest({ mutualId: 'm1', targetId: 't1', note: 'x'.repeat(100) })
      ).rejects.toBeInstanceOf(IntroRateLimitError);
    });

    it('maps other Postgrest errors onto the generic IntroError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '42501', message: 'no connection to mutual' },
      });
      await expect(
        sendWarmRequest({ mutualId: 'm1', targetId: 't1', note: 'x'.repeat(100) })
      ).rejects.toBeInstanceOf(IntroError);
    });
  });

  describe('forwardWarmIntro', () => {
    it('calls forward_warm_intro RPC with snake_case params and returns the new id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: 'forward-id', error: null });
      const id = await forwardWarmIntro({
        introId: 'i1',
        note: 'y'.repeat(120),
      });
      expect(supabase.rpc).toHaveBeenCalledWith('forward_warm_intro', {
        p_intro_id: 'i1',
        p_note: 'y'.repeat(120),
      });
      expect(id).toBe('forward-id');
    });

    it('throws IntroError on RPC failure', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '22023', message: 'warm request not in delivered state' },
      });
      await expect(
        forwardWarmIntro({ introId: 'i1', note: 'y'.repeat(120) })
      ).rejects.toBeInstanceOf(IntroError);
    });
  });
});
