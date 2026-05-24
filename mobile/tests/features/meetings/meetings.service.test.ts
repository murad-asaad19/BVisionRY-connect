jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn(), from: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  proposeMeeting,
  confirmMeeting,
  declineMeeting,
  fetchMeetingProposals,
  fetchPendingMeetingReviews,
} from '~/features/meetings/services/meetings.service';

describe('meetings.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('proposeMeeting calls RPC with correct args', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: { id: 'mp1' }, error: null });
    await proposeMeeting({
      conversationId: 'c1',
      slots: ['2030-01-01T00:00:00Z'],
      durationMinutes: 30,
      meetingUrl: null,
      timezone: 'America/Los_Angeles',
    });
    expect(supabase.rpc).toHaveBeenCalledWith('propose_meeting', {
      p_conversation_id: 'c1',
      p_slots: ['2030-01-01T00:00:00Z'],
      p_duration_minutes: 30,
      p_meeting_url: null,
      p_timezone: 'America/Los_Angeles',
    });
  });

  it('confirmMeeting calls RPC with id+slot', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({
      data: { id: 'mp1', state: 'confirmed' },
      error: null,
    });
    await confirmMeeting('mp1', '2030-01-01T00:00:00Z');
    expect(supabase.rpc).toHaveBeenCalledWith('confirm_meeting', {
      p_meeting_id: 'mp1',
      p_slot: '2030-01-01T00:00:00Z',
    });
  });

  it('declineMeeting calls RPC', async () => {
    (supabase.rpc as jest.Mock).mockResolvedValueOnce({
      data: { id: 'mp1', state: 'declined' },
      error: null,
    });
    await declineMeeting('mp1');
    expect(supabase.rpc).toHaveBeenCalledWith('decline_meeting', { p_meeting_id: 'mp1' });
  });

  it('fetchMeetingProposals selects by conversation_id ordered by created_at desc', async () => {
    const rows = [{ id: 'mp1' }];
    const order = jest.fn().mockResolvedValueOnce({ data: rows, error: null });
    const eq = jest.fn().mockReturnValue({ order });
    const select = jest.fn().mockReturnValue({ eq });
    (supabase.from as jest.Mock).mockReturnValue({ select });
    const result = await fetchMeetingProposals('c1');
    expect(supabase.from).toHaveBeenCalledWith('meeting_proposals');
    expect(eq).toHaveBeenCalledWith('conversation_id', 'c1');
    expect(order).toHaveBeenCalledWith('created_at', { ascending: false });
    expect(result).toEqual(rows);
  });

  describe('fetchPendingMeetingReviews', () => {
    it('passes p_conversation_id when supplied', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [{ id: 'mp1' }], error: null });
      const rows = await fetchPendingMeetingReviews('me', 'c1');
      expect(supabase.rpc).toHaveBeenCalledWith('pending_meeting_reviews', {
        p_conversation_id: 'c1',
      });
      expect(rows).toEqual([{ id: 'mp1' }]);
    });

    it('passes p_conversation_id: null when conversationId is omitted', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });
      await fetchPendingMeetingReviews('me');
      expect(supabase.rpc).toHaveBeenCalledWith('pending_meeting_reviews', {
        p_conversation_id: null,
      });
    });
  });
});
