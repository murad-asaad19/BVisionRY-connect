import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type MeetingProposalRow = Database['public']['Tables']['meeting_proposals']['Row'];
export type MeetingState = Database['public']['Enums']['meeting_state'];

export async function proposeMeeting(params: {
  conversationId: string;
  slots: string[];
  durationMinutes: number;
  meetingUrl: string | null;
  timezone: string | null;
}): Promise<MeetingProposalRow> {
  const { data, error } = await supabase.rpc('propose_meeting', {
    p_conversation_id: params.conversationId,
    p_slots: params.slots,
    p_duration_minutes: params.durationMinutes,
    p_meeting_url: params.meetingUrl as string | undefined,
    p_timezone: params.timezone as string | undefined,
  });
  if (error) throw new Error(error.message);
  return data as MeetingProposalRow;
}

export async function confirmMeeting(meetingId: string, slot: string): Promise<MeetingProposalRow> {
  const { data, error } = await supabase.rpc('confirm_meeting', {
    p_meeting_id: meetingId,
    p_slot: slot,
  });
  if (error) throw new Error(error.message);
  return data as MeetingProposalRow;
}

export async function declineMeeting(meetingId: string): Promise<MeetingProposalRow> {
  const { data, error } = await supabase.rpc('decline_meeting', { p_meeting_id: meetingId });
  if (error) throw new Error(error.message);
  return data as MeetingProposalRow;
}

/**
 * Proposer-only cancellation of an in-flight ('proposed') meeting.
 * Backed by the `cancel_meeting` RPC added in `20260606100000_meetings_fixes.sql`.
 */
export async function cancelMeeting(meetingId: string): Promise<MeetingProposalRow> {
  // cast: cancel_meeting was added after the last types.gen regen.
  const { data, error } = await (supabase.rpc as unknown as (
    fn: 'cancel_meeting',
    args: { p_meeting_id: string }
  ) => Promise<{ data: MeetingProposalRow | null; error: { message: string } | null }>)(
    'cancel_meeting',
    { p_meeting_id: meetingId }
  );
  if (error) throw new Error(error.message);
  return data as MeetingProposalRow;
}

export type MeetingReviewRow = Database['public']['Tables']['meeting_reviews']['Row'];
export type MeetingOutcome = 'useful' | 'not_useful' | 'no_show';

export async function submitMeetingReview(params: {
  meetingId: string;
  outcome: MeetingOutcome;
  note: string | null;
}): Promise<MeetingReviewRow> {
  const { data, error } = await supabase.rpc('submit_meeting_review', {
    p_meeting_id: params.meetingId,
    p_outcome: params.outcome,
    p_note: (params.note ?? '') as string,
  });
  if (error) throw new Error(error.message);
  return data as MeetingReviewRow;
}

/**
 * Fetch pending (no review yet) meetings whose confirmed_slot + duration is in
 * the past for the current user, capped to the past 14 days. Backed by the
 * `pending_meeting_reviews` RPC which enforces all filters server-side.
 *
 * `userId` is accepted for API compatibility with the previous client-side
 * implementation but is unused — the RPC scopes by `auth.uid()`.
 * `conversationId`, if provided, is passed through to the RPC as
 * `p_conversation_id` so the PostMeetingPrompt rendered inside a chat only
 * surfaces reviews tied to that conversation. Pass `undefined` to fetch
 * across every conversation.
 */
export async function fetchPendingMeetingReviews(
  _userId: string,
  conversationId?: string
): Promise<MeetingProposalRow[]> {
  const { data, error } = await (supabase.rpc as unknown as (
    fn: 'pending_meeting_reviews',
    args: { p_conversation_id: string | null }
  ) => Promise<{ data: MeetingProposalRow[] | null; error: { message: string } | null }>)(
    'pending_meeting_reviews',
    { p_conversation_id: conversationId ?? null }
  );
  if (error) throw new Error(error.message);
  return (data ?? []) as MeetingProposalRow[];
}

export async function fetchMeetingProposals(conversationId: string): Promise<MeetingProposalRow[]> {
  const { data, error } = await supabase
    .from('meeting_proposals')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: false });
  if (error) throw new Error(error.message);
  return data ?? [];
}
