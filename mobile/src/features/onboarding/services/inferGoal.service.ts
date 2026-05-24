import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

type GoalType = Database['public']['Enums']['goal_type'];
type RoleKind = Database['public']['Enums']['role_kind'];

const GOAL_TYPES: readonly GoalType[] = [
  'hire',
  'be_hired',
  'co_found',
  'invest',
  'take_investment',
  'advise',
  'find_advisor',
  'peer_connect',
];
const GOAL_TYPE_SET: ReadonlySet<string> = new Set(GOAL_TYPES);

export type InferGoalInput = {
  text: string;
  primaryRole: RoleKind | null;
  roles: RoleKind[];
};

export type InferGoalResult = {
  goalType: GoalType | null;
  confidence: 'high' | 'low';
};

/**
 * Calls the `infer-goal-type` edge function with the user's free-form goal
 * description and (optional) role context. Returns the model's classification
 * plus a confidence flag.
 *
 * Failure modes (network, 401, 5xx, malformed response, unknown enum value)
 * all collapse to `{ goalType: null, confidence: 'low' }` — the caller can
 * decide whether to surface a quiet caption or stay silent. We never throw
 * for inference failures because the user can always pick manually; throwing
 * would force every caller to wrap in try/catch for a non-fatal hint.
 *
 * The supabase-js client attaches the user's JWT automatically — the edge
 * function uses it to enforce `verify_jwt = true`.
 *
 * Pass an `AbortSignal` to cancel an in-flight request when the input
 * changes (caller responsibility — debouncing on top of this is also the
 * caller's job).
 */
export async function inferGoalType(
  input: InferGoalInput,
  signal?: AbortSignal
): Promise<InferGoalResult> {
  const failed: InferGoalResult = { goalType: null, confidence: 'low' };

  try {
    const { data, error } = await supabase.functions.invoke<{
      goal_type: GoalType | null;
      confidence: 'high' | 'low';
    }>('infer-goal-type', {
      body: {
        text: input.text,
        primary_role: input.primaryRole,
        roles: input.roles,
      },
      ...(signal ? { signal } : {}),
    });

    if (error) return failed;
    if (!data || typeof data !== 'object') return failed;

    const rawType = (data as { goal_type?: unknown }).goal_type;
    const rawConf = (data as { confidence?: unknown }).confidence;

    const goalType =
      typeof rawType === 'string' && GOAL_TYPE_SET.has(rawType)
        ? (rawType as GoalType)
        : null;
    const confidence: 'high' | 'low' = rawConf === 'high' ? 'high' : 'low';

    // Defensive: if the server claims "high" but we don't recognize the
    // enum value, treat as a failed inference. Prevents a server bug from
    // pre-selecting an invalid radio.
    if (goalType === null) return failed;

    return { goalType, confidence };
  } catch {
    return failed;
  }
}
