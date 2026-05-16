import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import type { Database } from '~/lib/supabase/types.gen';

type RoleKind = Database['public']['Enums']['role_kind'];
type GoalType = Database['public']['Enums']['goal_type'];

export type OnboardingDraft = {
  name?: string;
  handle?: string;
  roles?: RoleKind[];
  primary_role?: RoleKind;
  goal_type?: GoalType;
  goal_text?: string;
  city?: string;
  country?: string;
  headline?: string;
  bio?: string;
};

type State = {
  draft: OnboardingDraft;
  setField: <K extends keyof OnboardingDraft>(key: K, value: OnboardingDraft[K]) => void;
  reset: () => void;
};

export const useOnboardingDraft = create<State>()(
  persist(
    (set) => ({
      draft: {},
      setField: (key, value) => set((s) => ({ draft: { ...s.draft, [key]: value } })),
      reset: () => set({ draft: {} }),
    }),
    {
      name: 'onboarding-draft-v1',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
