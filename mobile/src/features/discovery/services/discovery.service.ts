import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type DailyMatchRow = Database['public']['Tables']['daily_matches']['Row'];

export type FeedRow =
  Database['public']['Functions']['search_discoverable_profiles']['Returns'][number];

export type FeedFilters = {
  query?: string;
  roles?: Database['public']['Enums']['role_kind'][];
  goalTypes?: Database['public']['Enums']['goal_type'][];
  country?: string;
};

export async function fetchDailyMatches(): Promise<DailyMatchRow[]> {
  const { data, error } = await supabase.rpc('get_daily_matches');
  if (error) throw new Error(error.message);
  return data ?? [];
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

  const { data, error } = await supabase.rpc('search_discoverable_profiles', {
    p_query: trimmedQuery.length > 0 ? trimmedQuery : undefined,
    p_roles: f?.roles && f.roles.length > 0 ? f.roles : undefined,
    p_goal_types: f?.goalTypes && f.goalTypes.length > 0 ? f.goalTypes : undefined,
    p_country: trimmedCountry.length > 0 ? trimmedCountry : undefined,
    p_cursor: params.cursor,
    p_limit: params.pageSize,
  });

  if (error) throw new Error(error.message);
  const rows = (data ?? []) as FeedRow[];
  const nextCursor = rows.length === params.pageSize ? rows[rows.length - 1]!.created_at : null;
  return { rows, nextCursor };
}
