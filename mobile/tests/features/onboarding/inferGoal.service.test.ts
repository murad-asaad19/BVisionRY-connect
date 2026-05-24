/**
 * Coverage for the `inferGoalType` service that wraps the `infer-goal-type`
 * edge function. The service must:
 *   - Forward `{ text, primary_role, roles }` and an optional AbortSignal to
 *     `supabase.functions.invoke`.
 *   - Return the canonical `{ goalType, confidence }` shape on success.
 *   - Collapse every failure mode (network error, 401, 5xx, malformed
 *     response, unknown enum value) to `{ goalType: null, confidence: 'low' }`
 *     instead of throwing — the goal-step caller treats a failed inference
 *     as a quiet caption, not an error toast.
 */

jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    functions: { invoke: jest.fn() },
  },
}));

import { supabase } from '~/lib/supabase/client';
import { inferGoalType } from '~/features/onboarding/services/inferGoal.service';

describe('inferGoal.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('success path', () => {
    it('invokes the edge function with snake_case body and returns the parsed result', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { goal_type: 'hire', confidence: 'high' },
        error: null,
      });

      const result = await inferGoalType({
        text: 'Looking to hire a senior backend engineer for the team',
        primaryRole: 'founder',
        roles: ['founder', 'leader'],
      });

      expect(supabase.functions.invoke).toHaveBeenCalledWith('infer-goal-type', {
        body: {
          text: 'Looking to hire a senior backend engineer for the team',
          primary_role: 'founder',
          roles: ['founder', 'leader'],
        },
      });
      expect(result).toEqual({ goalType: 'hire', confidence: 'high' });
    });

    it('forwards an AbortSignal when provided', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { goal_type: 'invest', confidence: 'high' },
        error: null,
      });
      const controller = new AbortController();

      await inferGoalType(
        {
          text: 'I write checks and lead seed rounds — actively investing',
          primaryRole: 'investor',
          roles: ['investor'],
        },
        controller.signal
      );

      const callArgs = (supabase.functions.invoke as jest.Mock).mock.calls[0][1];
      expect(callArgs.signal).toBe(controller.signal);
    });
  });

  describe('low-confidence outcomes', () => {
    it('returns null + low when the server returns goal_type: null', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { goal_type: null, confidence: 'low' },
        error: null,
      });

      const result = await inferGoalType({
        text: 'Just here to meet interesting people in tech',
        primaryRole: null,
        roles: [],
      });
      expect(result).toEqual({ goalType: null, confidence: 'low' });
    });
  });

  describe('failure modes — all collapse to { null, low } without throwing', () => {
    it('returns null + low on a 401 error from supabase', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'unauthenticated', status: 401 },
      });
      const result = await inferGoalType({
        text: 'Looking to hire a senior backend engineer',
        primaryRole: 'founder',
        roles: ['founder'],
      });
      expect(result).toEqual({ goalType: null, confidence: 'low' });
    });

    it('returns null + low on a 500 error from supabase', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { message: 'server_misconfigured', status: 500 },
      });
      const result = await inferGoalType({
        text: 'Looking to hire a senior backend engineer',
        primaryRole: 'founder',
        roles: ['founder'],
      });
      expect(result).toEqual({ goalType: null, confidence: 'low' });
    });

    it('returns null + low on a network/thrown error', async () => {
      (supabase.functions.invoke as jest.Mock).mockRejectedValueOnce(
        new Error('network down')
      );
      const result = await inferGoalType({
        text: 'Looking to hire a senior backend engineer',
        primaryRole: null,
        roles: [],
      });
      expect(result).toEqual({ goalType: null, confidence: 'low' });
    });

    it('returns null + low when the server returns a malformed body (no goal_type)', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { something: 'else' },
        error: null,
      });
      const result = await inferGoalType({
        text: 'Looking to hire a senior backend engineer',
        primaryRole: null,
        roles: [],
      });
      expect(result).toEqual({ goalType: null, confidence: 'low' });
    });

    it('returns null + low when the server returns an unknown enum value', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: { goal_type: 'not_a_real_enum_value', confidence: 'high' },
        error: null,
      });
      const result = await inferGoalType({
        text: 'Looking to hire a senior backend engineer',
        primaryRole: null,
        roles: [],
      });
      expect(result).toEqual({ goalType: null, confidence: 'low' });
    });

    it('returns null + low when data is null', async () => {
      (supabase.functions.invoke as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: null,
      });
      const result = await inferGoalType({
        text: 'Looking to hire a senior backend engineer',
        primaryRole: null,
        roles: [],
      });
      expect(result).toEqual({ goalType: null, confidence: 'low' });
    });
  });
});
