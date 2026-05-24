import { supabase } from '~/lib/supabase/client';

/**
 * AI-generated meeting playbook — a per-(meeting, viewer) briefing card.
 *
 * Read flow:
 *   * `getMeetingPlaybook(meetingId)` — cheap RPC (`get_meeting_playbook`)
 *     that returns the cached row from the DB or `null` if none exists.
 *   * `generateMeetingPlaybook(meetingId, force?)` — calls the
 *     `meeting-playbook` edge function which generates (or returns a fresh
 *     cached copy) and upserts into the table. Returns the canonical shape.
 */
export type MeetingPlaybook = {
  summary: string;
  sharedInterests: string[];
  conversationStarters: string[];
  doNotes: string[];
  dontNotes: string[];
  generatedAt: string;
};

// Server side snake_case payload — used for both the RPC return shape and
// the edge function response (they're intentionally identical).
type ServerPlaybook = {
  summary: string;
  shared_interests: string[];
  conversation_starters: string[];
  do_notes: string[];
  dont_notes: string[];
  generated_at: string;
};

function toClient(row: ServerPlaybook): MeetingPlaybook {
  return {
    summary: row.summary,
    sharedInterests: row.shared_interests ?? [],
    conversationStarters: row.conversation_starters ?? [],
    doNotes: row.do_notes ?? [],
    dontNotes: row.dont_notes ?? [],
    generatedAt: row.generated_at,
  };
}

/**
 * Reads the cached playbook row for the calling viewer via the
 * `get_meeting_playbook` RPC. Returns `null` when:
 *   * no playbook has been generated yet, or
 *   * the caller is not a participant in the meeting (the RPC silently
 *     returns an empty set in that case — we don't distinguish).
 *
 * Throws on transport / DB errors so React Query can surface them.
 */
export async function getMeetingPlaybook(
  meetingId: string
): Promise<MeetingPlaybook | null> {
  // The RPC was added after the last types.gen regen — cast through unknown.
  const { data, error } = await (
    supabase.rpc as unknown as (
      fn: 'get_meeting_playbook',
      args: { p_meeting_id: string }
    ) => Promise<{ data: ServerPlaybook[] | null; error: { message: string } | null }>
  )('get_meeting_playbook', { p_meeting_id: meetingId });

  if (error) throw new Error(error.message);
  if (!data || data.length === 0) return null;
  return toClient(data[0]);
}

/**
 * Generates a fresh playbook (or returns a server-side cached copy) via the
 * `meeting-playbook` edge function. Set `force` to bypass the server-side
 * cache and force a Claude regeneration. Throws on any error from the edge
 * function so the mutation surface can show a retry banner.
 */
export async function generateMeetingPlaybook(
  meetingId: string,
  force = false
): Promise<MeetingPlaybook> {
  const { data, error } = await supabase.functions.invoke<ServerPlaybook>(
    'meeting-playbook',
    { body: { meeting_id: meetingId, force } }
  );
  if (error) throw new Error(error.message ?? 'meeting-playbook failed');
  if (!data || typeof data !== 'object') {
    throw new Error('meeting-playbook returned empty body');
  }
  // Defensive shape check — every list field defaults to [] in the table.
  if (typeof (data as ServerPlaybook).summary !== 'string') {
    throw new Error('meeting-playbook returned malformed body');
  }
  return toClient(data as ServerPlaybook);
}
