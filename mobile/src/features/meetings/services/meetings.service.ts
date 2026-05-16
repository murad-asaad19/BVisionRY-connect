import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type MeetingProposalRow = Database['public']['Tables']['meeting_proposals']['Row'];
export type MeetingFeedbackRow = Database['public']['Tables']['meeting_feedback']['Row'];
export type MeetingState = Database['public']['Enums']['meeting_state'];
export type Rating = Database['public']['Enums']['meeting_feedback_rating'];

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

export async function submitFeedback(params: {
  meetingId: string;
  rating: Rating;
  note: string | null;
}): Promise<MeetingFeedbackRow> {
  const { data, error } = await supabase.rpc('submit_meeting_feedback', {
    p_meeting_id: params.meetingId,
    p_rating: params.rating,
    p_note: params.note as string | undefined,
  });
  if (error) throw new Error(error.message);
  return data as MeetingFeedbackRow;
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
 * Fetch pending (no review yet) meetings whose confirmed slot + duration is in
 * the past for the current user. Used by PostMeetingPrompt.
 */
export async function fetchPendingMeetingReviews(
  userId: string,
  conversationId?: string
): Promise<MeetingProposalRow[]> {
  let query = supabase
    .from('meeting_proposals')
    .select('*')
    .eq('state', 'confirmed')
    .not('confirmed_slot', 'is', null)
    .order('confirmed_slot', { ascending: false });
  if (conversationId) query = query.eq('conversation_id', conversationId);
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  const proposals = (data ?? []) as MeetingProposalRow[];
  const now = Date.now();
  const past = proposals.filter((p) => {
    if (!p.confirmed_slot) return false;
    const end = new Date(p.confirmed_slot).getTime() + (p.duration_minutes ?? 0) * 60_000;
    return end < now;
  });
  if (past.length === 0) return [];
  // Exclude meetings already reviewed by this user
  const meetingIds = past.map((p) => p.id);
  const { data: reviews } = await supabase
    .from('meeting_reviews')
    .select('meeting_id')
    .in('meeting_id', meetingIds)
    .eq('reviewer_id', userId);
  const reviewed = new Set((reviews ?? []).map((r) => r.meeting_id));
  return past.filter((p) => !reviewed.has(p.id));
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

export async function fetchMyFeedbackForMeeting(
  meetingId: string,
  userId: string
): Promise<MeetingFeedbackRow | null> {
  const { data, error } = await supabase
    .from('meeting_feedback')
    .select('*')
    .eq('meeting_id', meetingId)
    .eq('rater_id', userId)
    .single();
  if (error) {
    if (error.code === 'PGRST116') return null;
    throw new Error(error.message);
  }
  return data;
}
