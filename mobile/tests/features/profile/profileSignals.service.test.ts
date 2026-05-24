jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import { getProfileSignals } from '~/features/profile/services/profileSignals.service';

describe('profileSignals.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('maps snake_case RPC row → camelCase ProfileSignals', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({
      data: [
        {
          mutual_connection_count: 3,
          mutual_top_user_ids: ['u1', 'u2', 'u3'],
          avg_meeting_rating: 4.5,
          total_meeting_reviews: 7,
        },
      ],
      error: null,
    });

    const result = await getProfileSignals('target-id');

    expect(supabase.rpc).toHaveBeenCalledWith('get_profile_signals', { p_target: 'target-id' });
    expect(result).toEqual({
      mutualConnectionCount: 3,
      mutualTopUserIds: ['u1', 'u2', 'u3'],
      avgMeetingRating: 4.5,
      totalMeetingReviews: 7,
    });
  });

  it('parses string-encoded numeric(2,1) avg_meeting_rating into a number', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({
      data: [
        {
          mutual_connection_count: 0,
          mutual_top_user_ids: [],
          avg_meeting_rating: '4.3',
          total_meeting_reviews: 4,
        },
      ],
      error: null,
    });

    const result = await getProfileSignals('target-id');
    expect(result.avgMeetingRating).toBeCloseTo(4.3, 5);
  });

  it('preserves null avg_meeting_rating (below-threshold case)', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({
      data: [
        {
          mutual_connection_count: 1,
          mutual_top_user_ids: ['u1'],
          avg_meeting_rating: null,
          total_meeting_reviews: 2,
        },
      ],
      error: null,
    });

    const result = await getProfileSignals('target-id');
    expect(result.avgMeetingRating).toBeNull();
    expect(result.totalMeetingReviews).toBe(2);
  });

  it('tolerates single-object data shape (defensive forward-compat)', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({
      data: {
        mutual_connection_count: 2,
        mutual_top_user_ids: ['x', 'y'],
        avg_meeting_rating: null,
        total_meeting_reviews: 1,
      },
      error: null,
    });

    const result = await getProfileSignals('target-id');
    expect(result.mutualConnectionCount).toBe(2);
    expect(result.mutualTopUserIds).toEqual(['x', 'y']);
  });

  it('returns zeros when data is null', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
    const result = await getProfileSignals('target-id');
    expect(result).toEqual({
      mutualConnectionCount: 0,
      mutualTopUserIds: [],
      avgMeetingRating: null,
      totalMeetingReviews: 0,
    });
  });

  it('throws on RPC error', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({
      data: null,
      error: { message: 'rpc fail' },
    });
    await expect(getProfileSignals('target-id')).rejects.toThrow('rpc fail');
  });
});
