import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Per-user nudge state. Keyed by userId so that signing in as a different
// account on the same device does not inherit prior dismissals. Timestamps
// are ISO 8601 strings — when they age past TTL_DAYS we re-show the nudge so
// users get a periodic reminder if they never act on it.
type UserNudgeState = {
  photoNudgeDismissedAt?: string;
  goalNudgeDismissedAt?: string;
};

type State = {
  byUser: Record<string, UserNudgeState>;
  dismissPhotoNudge: (userId: string) => void;
  dismissGoalNudge: (userId: string) => void;
  /** Wipe a single user's nudge state (e.g. account switch on same device). */
  clearForUser: (userId: string) => void;
  /**
   * Wipe ALL users' nudge state. Called from `auth.signOut()` — see
   * `mobile/src/features/auth/services/auth.service.ts`. Keeps the existing
   * sign-out contract intact: the store is fully reset on logout so the next
   * account on the device gets a clean slate.
   */
  reset: () => void;
};

const DAY_MS = 24 * 60 * 60 * 1000;
const PHOTO_NUDGE_TTL_DAYS = 30;
const GOAL_NUDGE_TTL_DAYS = 14;

function isWithin(iso: string | undefined, ttlDays: number): boolean {
  if (!iso) return false;
  const ts = Date.parse(iso);
  if (Number.isNaN(ts)) return false;
  return Date.now() - ts < ttlDays * DAY_MS;
}

export const useProfileNudgeStore = create<State>()(
  persist(
    (set) => ({
      byUser: {},
      dismissPhotoNudge: (userId) =>
        set((s) => ({
          byUser: {
            ...s.byUser,
            [userId]: {
              ...(s.byUser[userId] ?? {}),
              photoNudgeDismissedAt: new Date().toISOString(),
            },
          },
        })),
      dismissGoalNudge: (userId) =>
        set((s) => ({
          byUser: {
            ...s.byUser,
            [userId]: {
              ...(s.byUser[userId] ?? {}),
              goalNudgeDismissedAt: new Date().toISOString(),
            },
          },
        })),
      clearForUser: (userId) =>
        set((s) => {
          if (!(userId in s.byUser)) return s;
          // Omit the key by destructuring out the userId entry.
          const { [userId]: _omit, ...rest } = s.byUser;
          return { byUser: rest };
        }),
      reset: () => set({ byUser: {} }),
    }),
    {
      name: 'profile-nudge-v2',
      version: 2,
      storage: createJSONStorage(() => AsyncStorage),
      // v1 stored a flat `{ photoNudgeDismissed: boolean }`. The user it
      // belonged to is unknown at migration time, so drop it — worst case the
      // banner reappears once for an existing user, which is acceptable.
      migrate: (_persisted, _version) => ({ byUser: {} }),
    }
  )
);

/**
 * Selector helpers — keep TTL logic in one place so banners don't drift apart.
 * Both return `true` when the user dismissed the nudge AND the dismissal is
 * still fresh; `false` when they never dismissed or the dismissal expired.
 */
export function isPhotoNudgeDismissed(state: State, userId: string | undefined): boolean {
  if (!userId) return false;
  return isWithin(state.byUser[userId]?.photoNudgeDismissedAt, PHOTO_NUDGE_TTL_DAYS);
}

export function isGoalNudgeDismissed(state: State, userId: string | undefined): boolean {
  if (!userId) return false;
  return isWithin(state.byUser[userId]?.goalNudgeDismissedAt, GOAL_NUDGE_TTL_DAYS);
}

export { PHOTO_NUDGE_TTL_DAYS, GOAL_NUDGE_TTL_DAYS };
