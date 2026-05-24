import { useCallback, useEffect, useRef } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  generateMeetingPlaybook,
  getMeetingPlaybook,
  type MeetingPlaybook,
} from '~/features/meetings/services/playbook.service';

/**
 * Stale-while-revalidate window for the cached playbook row. If `generated_at`
 * is older than this, the hook fires a background regeneration on mount. The
 * server has its own 7d TTL — this is just the client-side "feels fresh"
 * threshold so a meeting starting in the next hour gets the latest prompt.
 */
const STALE_AFTER_MS = 60 * 60 * 1000; // 1h

/**
 * Cooldown between user-initiated regenerations. The UI disables the
 * "Regenerate" CTA while this is active and surfaces a "Available again in
 * an hour" caption.
 */
const REGEN_COOLDOWN_MS = 60 * 60 * 1000; // 1h

export type UseMeetingPlaybookResult = {
  playbook: MeetingPlaybook | null;
  isLoading: boolean;
  isGenerating: boolean;
  error: Error | null;
  /** True until the cooldown elapses; the button should be disabled. */
  isRateLimited: boolean;
  /** Manually trigger a regen (subject to the cooldown). */
  regenerate: () => void;
};

/**
 * Composite hook backing `<MeetingPlaybookCard>`:
 *   1. On mount, fetch the cached row via `get_meeting_playbook` (cheap RPC).
 *   2. If the row is missing OR older than the SWR window, kick off a
 *      generation through the edge function in the background.
 *   3. Expose a `regenerate()` callback for the manual button. Rate-limited
 *      to once per hour using a `useRef` last-call timestamp.
 */
export function useMeetingPlaybook(meetingId: string): UseMeetingPlaybookResult {
  const qc = useQueryClient();
  const queryKey = ['meeting-playbook', meetingId];
  const lastGenAt = useRef<number>(0);
  // Tracks the in-mount auto-regen so we don't fire it twice if React strict
  // mode double-invokes effects.
  const autoGenFiredRef = useRef(false);

  const query = useQuery<MeetingPlaybook | null, Error>({
    queryKey,
    queryFn: () => getMeetingPlaybook(meetingId),
    enabled: !!meetingId,
    staleTime: STALE_AFTER_MS,
  });

  const mutation = useMutation<MeetingPlaybook, Error, { force: boolean }>({
    mutationFn: ({ force }) => generateMeetingPlaybook(meetingId, force),
    onSuccess: (data) => {
      qc.setQueryData<MeetingPlaybook | null>(queryKey, data);
      lastGenAt.current = Date.now();
    },
  });

  // Background regen-on-mount: only when we have no row, or the row is stale.
  // Does NOT bump the lastGenAt rate limit — that's reserved for explicit
  // user-initiated regenerations so the manual button isn't pre-emptively
  // disabled.
  useEffect(() => {
    if (!query.isSuccess || autoGenFiredRef.current || mutation.isPending) return;
    const row = query.data;
    if (!row) {
      autoGenFiredRef.current = true;
      mutation.mutate({ force: false });
      return;
    }
    const ageMs = Date.now() - new Date(row.generatedAt).getTime();
    if (ageMs > STALE_AFTER_MS) {
      autoGenFiredRef.current = true;
      mutation.mutate({ force: false });
    }
    // Intentionally narrow deps — we only act when the underlying RPC result
    // settles (isSuccess flip) so the cache-miss / stale-row check runs once
    // per fresh fetch.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [query.isSuccess, query.data?.generatedAt]);

  const isRateLimited =
    lastGenAt.current > 0 && Date.now() - lastGenAt.current < REGEN_COOLDOWN_MS;

  const regenerate = useCallback(() => {
    if (mutation.isPending) return;
    if (lastGenAt.current > 0 && Date.now() - lastGenAt.current < REGEN_COOLDOWN_MS) {
      return;
    }
    mutation.mutate({ force: true });
  }, [mutation]);

  const playbook = mutation.data ?? query.data ?? null;
  const error = (mutation.error ?? query.error ?? null) as Error | null;

  return {
    playbook,
    isLoading: query.isLoading,
    isGenerating: mutation.isPending,
    error,
    isRateLimited,
    regenerate,
  };
}
