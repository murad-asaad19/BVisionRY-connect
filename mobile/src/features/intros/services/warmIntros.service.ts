import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';
import {
  IntroDuplicateError,
  IntroError,
  IntroRateLimitError,
} from '~/features/intros/services/intros.service';

/**
 * Warm intro suggestions + the two action RPCs (send_warm_request,
 * forward_warm_intro). All three RPCs are defined in
 * supabase/migrations/20260608010000_second_degree_intros.sql and
 * granted to `authenticated` only.
 *
 * The Supabase TS types (`types.gen.ts`) haven't been regenerated for
 * these RPCs yet (Task 7 owns that step). We cast through `unknown` at
 * the call site so the rest of the codebase stays strictly typed.
 */

export type RoleKind = Database['public']['Enums']['role_kind'];
export type GoalType = Database['public']['Enums']['goal_type'];

export type WarmIntroSuggestion = {
  targetId: string;
  targetHandle: string;
  targetName: string;
  targetPhotoUrl: string | null;
  targetPrimaryRole: RoleKind | null;
  targetGoalType: GoalType | null;
  mutualCount: number;
  topMutualId: string;
  topMutualName: string;
  topMutualHandle: string;
};

type WarmIntroSuggestionRow = {
  target_id: string;
  target_handle: string;
  target_name: string;
  target_photo_url: string | null;
  target_primary_role: RoleKind | null;
  target_goal_type: GoalType | null;
  mutual_count: number;
  top_mutual_id: string;
  top_mutual_name: string;
  top_mutual_handle: string;
};

/** Map a raw RPC row to the camelCase DTO consumed by the UI. */
function mapSuggestion(row: WarmIntroSuggestionRow): WarmIntroSuggestion {
  return {
    targetId: row.target_id,
    targetHandle: row.target_handle,
    targetName: row.target_name,
    targetPhotoUrl: row.target_photo_url,
    targetPrimaryRole: row.target_primary_role,
    targetGoalType: row.target_goal_type,
    mutualCount: row.mutual_count,
    topMutualId: row.top_mutual_id,
    topMutualName: row.top_mutual_name,
    topMutualHandle: row.top_mutual_handle,
  };
}

/**
 * Map a PostgrestError raised by one of the warm-intro RPCs onto the
 * typed IntroError hierarchy so callers can branch on instanceof and
 * surface i18n'd copy. Reuses the same hierarchy as direct intros so
 * existing UI error handling code stays shared.
 */
function mapWarmIntroError(err: { code?: string | null; message?: string | null }): IntroError {
  const code = err.code ?? 'unknown';
  const msg = err.message ?? '';
  if (code === '23505' || /already exists|already pending|duplicate key/i.test(msg)) {
    return new IntroDuplicateError(msg);
  }
  if (code === 'P0001' && /daily cap|cap reached/i.test(msg)) {
    return new IntroRateLimitError(msg);
  }
  return new IntroError(code, msg);
}

export async function suggestWarmIntros(limit?: number): Promise<WarmIntroSuggestion[]> {
  const { data, error } = await (
    supabase.rpc as unknown as (
      fn: string,
      args: { p_limit: number }
    ) => Promise<{ data: WarmIntroSuggestionRow[] | null; error: { message: string } | null }>
  )('suggest_warm_intros', { p_limit: limit ?? 10 });
  if (error) throw new Error(error.message);
  return (data ?? []).map(mapSuggestion);
}

export async function sendWarmRequest(input: {
  mutualId: string;
  targetId: string;
  note: string;
}): Promise<string> {
  const { data, error } = await (
    supabase.rpc as unknown as (
      fn: string,
      args: { p_mutual_id: string; p_target_id: string; p_note: string }
    ) => Promise<{
      data: string | null;
      error: { code?: string | null; message?: string | null } | null;
    }>
  )('send_warm_request', {
    p_mutual_id: input.mutualId,
    p_target_id: input.targetId,
    p_note: input.note,
  });
  if (error) throw mapWarmIntroError(error);
  if (!data) throw new Error('send_warm_request returned no id');
  return data;
}

export async function forwardWarmIntro(input: {
  introId: string;
  note: string;
}): Promise<string> {
  const { data, error } = await (
    supabase.rpc as unknown as (
      fn: string,
      args: { p_intro_id: string; p_note: string }
    ) => Promise<{
      data: string | null;
      error: { code?: string | null; message?: string | null } | null;
    }>
  )('forward_warm_intro', {
    p_intro_id: input.introId,
    p_note: input.note,
  });
  if (error) throw mapWarmIntroError(error);
  if (!data) throw new Error('forward_warm_intro returned no id');
  return data;
}
