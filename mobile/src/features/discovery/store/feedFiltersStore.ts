import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Database } from '~/lib/supabase/types.gen';

export type RoleKind = Database['public']['Enums']['role_kind'];
export type GoalType = Database['public']['Enums']['goal_type'];

export type FeedFilters = {
  query: string;
  roles: RoleKind[];
  goalTypes: GoalType[];
  country: string;
};

type State = FeedFilters & {
  setQuery: (q: string) => void;
  toggleRole: (r: RoleKind) => void;
  toggleGoalType: (g: GoalType) => void;
  setCountry: (c: string) => void;
  clear: () => void;
};

const initial: FeedFilters = {
  query: '',
  roles: [],
  goalTypes: [],
  country: '',
};

/**
 * Persisted feed filters.
 *
 * `query` is excluded from persistence via `partialize` — search input is
 * ephemeral by intent (users don't want yesterday's search resurrected on
 * relaunch). Roles / goalTypes / country survive restart.
 *
 * Migration note: prior versions of this store used `create()` without
 * `persist`. Zustand's persist middleware simply hydrates from missing
 * storage as `undefined` and falls back to `initial`, so no explicit
 * migration handler is required.
 */
export const useFeedFiltersStore = create<State>()(
  persist(
    (set) => ({
      ...initial,
      setQuery: (q) => set({ query: q }),
      toggleRole: (r) =>
        set((s) => ({
          roles: s.roles.includes(r) ? s.roles.filter((x) => x !== r) : [...s.roles, r],
        })),
      toggleGoalType: (g) =>
        set((s) => ({
          goalTypes: s.goalTypes.includes(g)
            ? s.goalTypes.filter((x) => x !== g)
            : [...s.goalTypes, g],
        })),
      setCountry: (c) => set({ country: c }),
      clear: () => set(initial),
    }),
    {
      name: 'feed-filters',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (s) => ({
        roles: s.roles,
        goalTypes: s.goalTypes,
        country: s.country,
      }),
    }
  )
);
