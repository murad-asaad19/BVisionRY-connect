import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

/**
 * The legacy row shape (kept exported for any future caller that needs the
 * raw daily_matches table type — the widened RPC view shape lives below).
 */
export type DailyMatchRow = Database['public']['Tables']['daily_matches']['Row'];

/**
 * Widened shape returned by `get_daily_matches` (migration
 * 20260606090000_discovery_fixes.sql). Joins the picked profile so the UI
 * can render without an additional per-row profile fetch.
 *
 * Declared locally because `types.gen.ts` is regenerated from the live
 * schema and may not yet reflect the new return columns.
 */
export type DailyMatchView = {
  id: string;
  pick_user_id: string;
  match_reason: string;
  for_date_local: string;
  viewed_at: string | null;
  created_at: string;
  name: string | null;
  handle: string | null;
  photo_url: string | null;
  headline: string | null;
  bio: string | null;
  city: string | null;
  country: string | null;
  primary_role: Database['public']['Enums']['role_kind'] | null;
  roles: Database['public']['Enums']['role_kind'][] | null;
  goal_type: Database['public']['Enums']['goal_type'] | null;
};

export type FeedRow =
  Database['public']['Functions']['search_discoverable_profiles']['Returns'][number];

export type FeedFilters = {
  query?: string;
  roles?: Database['public']['Enums']['role_kind'][];
  goalTypes?: Database['public']['Enums']['goal_type'][];
  country?: string;
};

/**
 * Today's date in YYYY-MM-DD using the device's local timezone. Exported so
 * the query hook, the optimistic-update hook, and the service all key on the
 * exact same string.
 */
export function todayLocalIso(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export async function fetchDailyMatches(forDate?: string): Promise<DailyMatchView[]> {
  const { data, error } = await supabase.rpc('get_daily_matches', {
    p_for_date: forDate ?? todayLocalIso(),
  });
  if (error) throw new Error(error.message);
  // Cast: types.gen.ts is regenerated from the live schema and may not yet
  // know about the widened return columns added in the discovery_fixes
  // migration. The local DailyMatchView captures the actual shape.
  return (data ?? []) as unknown as DailyMatchView[];
}

export async function markMatchViewed(matchId: string): Promise<void> {
  const { error } = await supabase.rpc('mark_match_viewed', { p_match_id: matchId });
  if (error) throw new Error(error.message);
}

export async function fetchFeedPage(params: {
  currentUserId: string;
  cursor: string;
  pageSize: number;
  filters?: FeedFilters;
}): Promise<{ rows: FeedRow[]; nextCursor: string | null }> {
  const f = params.filters;
  const trimmedQuery = f?.query?.trim() ?? '';
  const trimmedCountry = f?.country?.trim() ?? '';

  // PostgREST coerces undefined inconsistently — pass explicit null so the
  // server-side function sees a NULL argument and falls through to its
  // default-NULL parameter behaviour. The generated Args type marks these
  // as `?: T` (undefined-only); supabase-js sends `null` over the wire just
  // fine, so cast through unknown to bypass the synthetic signature.
  const rpcArgs = {
    p_query: trimmedQuery.length > 0 ? trimmedQuery : null,
    p_roles: f?.roles && f.roles.length > 0 ? f.roles : null,
    p_goal_types: f?.goalTypes && f.goalTypes.length > 0 ? f.goalTypes : null,
    p_country: trimmedCountry.length > 0 ? trimmedCountry : null,
    p_cursor: params.cursor,
    p_limit: params.pageSize,
  };

  const { data, error } = await supabase.rpc(
    'search_discoverable_profiles',
    rpcArgs as unknown as {
      p_query?: string;
      p_roles?: Database['public']['Enums']['role_kind'][];
      p_goal_types?: Database['public']['Enums']['goal_type'][];
      p_country?: string;
      p_cursor?: string;
      p_limit?: number;
    }
  );

  if (error) throw new Error(error.message);
  const rows = (data ?? []) as FeedRow[];
  const nextCursor = rows.length === params.pageSize ? rows[rows.length - 1]!.created_at : null;
  return { rows, nextCursor };
}
