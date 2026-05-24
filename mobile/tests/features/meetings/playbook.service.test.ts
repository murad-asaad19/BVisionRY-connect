/**
 * Coverage for the meeting playbook service wrappers:
 *   * `getMeetingPlaybook(meetingId)` — RPC `get_meeting_playbook`, returns
 *     `null` when no row exists, snake→camel maps when present.
 *   * `generateMeetingPlaybook(meetingId, force?)` — edge-function
 *     `meeting-playbook`, forwards `{meeting_id, force}` and parses the
 *     ServerPlaybook shape.
 */

jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    rpc: jest.fn(),
    functions: { invoke: jest.fn() },
  },
}));

import { supabase } from '~/lib/supabase/client';
import {
  generateMeetingPlaybook,
  getMeetingPlaybook,
} from '~/features/meetings/services/playbook.service';

const SERVER_ROW = {
  summary: 'Bob is a designer who likes cycling.',
  shared_interests: ['Cycling', 'Berlin'],
  conversation_starters: ['What got you into UX?'],
  do_notes: ['Mention the cycling angle'],
  dont_notes: ["Don't open with a pitch"],
  generated_at: '2030-01-01T00:00:00Z',
};

const CLIENT_ROW = {
  summary: 'Bob is a designer who likes cycling.',
  sharedInterests: ['Cycling', 'Berlin'],
  conversationStarters: ['What got you into UX?'],
  doNotes: ['Mention the cycling angle'],
  dontNotes: ["Don't open with a pitch"],
  generatedAt: '2030-01-01T00:00:00Z',
};

describe('playbook.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('getMeetingPlaybook', () => {
    it('calls the get_meeting_playbook RPC with the meeting id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [SERVER_ROW],
        error: null,
      });
      const result = await getMeetingPlaybook('mp1');
      expect(supabase.rpc).toHaveBeenCalledWith('get_meeting_playbook', {
        p_meeting_id: 'mp1',
      });
      expect(result).toEqual(CLIENT_ROW);
    });

    it('returns null when the RPC returns an empty array (no row exists)', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });
      const result = await getMeetingPlaybook('mp1');
      expect(result).toBeNull();
    });

    it('returns null when the RPC returns null data', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      const result = await getMeetingPlaybook('mp1');
      expect(result).toBeNull();
    });

    it('throws when the RPC returns an error', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'unauthenticated' },
      });
      await expect(getMeetingPlaybook('mp1')).rejects.toThrow('unauthenticated');
    });
  });

  describe('generateMeetingPlaybook', () => {
    it('invokes the edge function with snake_case body (force=false by default)', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: SERVER_ROW,
        error: null,
      });
      const result = await generateMeetingPlaybook('mp1');
      expect(supabase.functions.invoke).toHaveBeenCalledWith('meeting-playbook', {
        body: { meeting_id: 'mp1', force: false },
      });
      expect(result).toEqual(CLIENT_ROW);
    });

    it('forwards force=true when the caller passes it', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: SERVER_ROW,
        error: null,
      });
      await generateMeetingPlaybook('mp1', true);
      expect(supabase.functions.invoke).toHaveBeenCalledWith('meeting-playbook', {
        body: { meeting_id: 'mp1', force: true },
      });
    });

    it('throws when the edge function returns an error', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'generation_failed', status: 502 },
      });
      await expect(generateMeetingPlaybook('mp1')).rejects.toThrow('generation_failed');
    });

    it('throws when the edge function returns an empty body', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: null,
      });
      await expect(generateMeetingPlaybook('mp1')).rejects.toThrow();
    });

    it('throws when the response shape is malformed', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { foo: 'bar' },
        error: null,
      });
      await expect(generateMeetingPlaybook('mp1')).rejects.toThrow();
    });
  });
});
