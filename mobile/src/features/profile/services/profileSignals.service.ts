import { supabase } from '~/lib/supabase/client';

/**
 * Trust signals surfaced on profile views.
 *
 * Backed by the `get_profile_signals(p_target)` RPC — see
 * `supabase/migrations/20260608000000_profile_signals.sql` for the
 * derivation rules and visibility guarantees (blocks, self-view,
 * ≥3-review threshold for avg).
 *
 * `avgMeetingRating` is intentionally null when `totalMeetingReviews < 3`
 * — the RPC enforces this so a single skewed review can't dominate.
 */
export type ProfileSignals = {
  mutualConnectionCount: number;
  mutualTopUserIds: string[];
  avgMeetingRating: number | null;
  totalMeetingReviews: number;
};

// types.gen.ts hasn't been regenerated for this RPC yet (Task 7 owns
// regeneration), so we declare a local shape that mirrors the RPC's
// return signature and cast at the call site.
type ProfileSignalsRow = {
  mutual_connection_count: number;
  mutual_top_user_ids: string[];
  avg_meeting_rating: number | string | null;
  total_meeting_reviews: number;
};

export async function getProfileSignals(targetUserId: string): Promise<ProfileSignals> {
  const { data, error } = await (supabase.rpc as unknown as (
    fn: string,
    args: { p_target: string }
  ) => Promise<{ data: ProfileSignalsRow[] | ProfileSignalsRow | null; error: { message: string } | null }>)(
    'get_profile_signals',
    { p_target: targetUserId }
  );

  if (error) throw new Error(error.message);

  // The RPC returns a TABLE (single row). PostgREST surfaces table-returning
  // functions as an array; tolerate both shapes for forward-compat.
  const row: ProfileSignalsRow | null = Array.isArray(data) ? (data[0] ?? null) : data;

  if (!row) {
    return {
      mutualConnectionCount: 0,
      mutualTopUserIds: [],
      avgMeetingRating: null,
      totalMeetingReviews: 0,
    };
  }

  // numeric(2,1) deserialises as string from PostgREST in some setups,
  // and as number in others (with the json-numeric coercion). Coerce
  // explicitly so consumers always get number | null.
  const avg =
    row.avg_meeting_rating === null || row.avg_meeting_rating === undefined
      ? null
      : typeof row.avg_meeting_rating === 'string'
        ? Number.parseFloat(row.avg_meeting_rating)
        : row.avg_meeting_rating;

  return {
    mutualConnectionCount: row.mutual_connection_count ?? 0,
    mutualTopUserIds: row.mutual_top_user_ids ?? [],
    avgMeetingRating: Number.isFinite(avg as number) ? (avg as number) : null,
    totalMeetingReviews: row.total_meeting_reviews ?? 0,
  };
}
