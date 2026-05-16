import { create } from 'zustand';
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

export const useFeedFiltersStore = create<State>((set) => ({
  ...initial,
  setQuery: (q) => set({ query: q }),
  toggleRole: (r) =>
    set((s) => ({
      roles: s.roles.includes(r) ? s.roles.filter((x) => x !== r) : [...s.roles, r],
    })),
  toggleGoalType: (g) =>
    set((s) => ({
      goalTypes: s.goalTypes.includes(g) ? s.goalTypes.filter((x) => x !== g) : [...s.goalTypes, g],
    })),
  setCountry: (c) => set({ country: c }),
  clear: () => set(initial),
}));
