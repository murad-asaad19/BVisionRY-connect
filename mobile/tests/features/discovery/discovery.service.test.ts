jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    rpc: jest.fn(),
    from: jest.fn(),
  },
}));

import { supabase } from '~/lib/supabase/client';
import {
  fetchDailyMatches,
  markMatchViewed,
  fetchFeedPage,
} from '~/features/discovery/services/discovery.service';

describe('discovery.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('fetchDailyMatches', () => {
    it('calls get_daily_matches RPC with p_for_date arg (defaults to today)', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });
      await fetchDailyMatches();
      expect(supabase.rpc).toHaveBeenCalledWith(
        'get_daily_matches',
        expect.objectContaining({ p_for_date: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/) })
      );
    });

    it('returns the row array', async () => {
      const rows = [{ id: 'm1', pick_user_id: 'u2' }];
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: rows, error: null });
      const result = await fetchDailyMatches();
      expect(result).toEqual(rows);
    });

    it('throws on RPC error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: { message: 'fail' } });
      await expect(fetchDailyMatches()).rejects.toThrow('fail');
    });
  });

  describe('markMatchViewed', () => {
    it('calls mark_match_viewed RPC with the match id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await markMatchViewed('match-123');
      expect(supabase.rpc).toHaveBeenCalledWith('mark_match_viewed', { p_match_id: 'match-123' });
    });
  });

  describe('fetchFeedPage', () => {
    it('calls search_discoverable_profiles RPC with cursor + limit and undefined filter args', async () => {
      const rows = [{ id: 'u2', handle: 'alice', created_at: '2026-05-14T00:00:00Z' }];
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: rows, error: null });

      const result = await fetchFeedPage({
        currentUserId: 'me',
        cursor: '2026-05-15T00:00:00Z',
        pageSize: 20,
      });

      // PostgREST coerces `undefined` inconsistently — the service passes
      // explicit `null` so the SQL function sees NULL args and applies its
      // default-NULL fallback behaviour.
      expect(supabase.rpc).toHaveBeenCalledWith('search_discoverable_profiles', {
        p_query: null,
        p_roles: null,
        p_goal_types: null,
        p_country: null,
        p_cursor: '2026-05-15T00:00:00Z',
        p_limit: 20,
      });
      expect(result.rows).toEqual(rows);
      expect(result.nextCursor).toBeNull();
    });

    it('passes filters when provided and trims query/country', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });

      await fetchFeedPage({
        currentUserId: 'me',
        cursor: '9999-12-31T00:00:00Z',
        pageSize: 20,
        filters: {
          query: '  ada  ',
          roles: ['builder', 'investor'],
          goalTypes: ['hire'],
          country: '  Germany ',
        },
      });

      expect(supabase.rpc).toHaveBeenCalledWith('search_discoverable_profiles', {
        p_query: 'ada',
        p_roles: ['builder', 'investor'],
        p_goal_types: ['hire'],
        p_country: 'Germany',
        p_cursor: '9999-12-31T00:00:00Z',
        p_limit: 20,
      });
    });

    it('coerces empty filter values to null (empty string / empty arrays)', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });

      await fetchFeedPage({
        currentUserId: 'me',
        cursor: '9999-12-31T00:00:00Z',
        pageSize: 20,
        filters: { query: '   ', roles: [], goalTypes: [], country: '' },
      });

      const callArgs = (supabase.rpc as jest.Mock).mock.calls[0]![1];
      expect(callArgs.p_query).toBeNull();
      expect(callArgs.p_roles).toBeNull();
      expect(callArgs.p_goal_types).toBeNull();
      expect(callArgs.p_country).toBeNull();
    });

    it('returns nextCursor when full page returned', async () => {
      const rows = Array.from({ length: 20 }).map((_, i) => ({
        id: `u${i}`,
        handle: `h${i}`,
        created_at: `2026-05-${String(10 + i).padStart(2, '0')}T00:00:00Z`,
      }));
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: rows, error: null });

      const result = await fetchFeedPage({
        currentUserId: 'me',
        cursor: '9999-12-31T00:00:00Z',
        pageSize: 20,
      });
      expect(result.rows.length).toBe(20);
      expect(result.nextCursor).toBe(rows[rows.length - 1]!.created_at);
    });

    it('throws on RPC error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'rpc fail' },
      });
      await expect(
        fetchFeedPage({ currentUserId: 'me', cursor: 'x', pageSize: 20 })
      ).rejects.toThrow('rpc fail');
    });
  });
});
