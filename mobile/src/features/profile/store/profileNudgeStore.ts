import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

type State = {
  photoNudgeDismissed: boolean;
  dismissPhotoNudge: () => void;
  reset: () => void;
};

export const useProfileNudgeStore = create<State>()(
  persist(
    (set) => ({
      photoNudgeDismissed: false,
      dismissPhotoNudge: () => set({ photoNudgeDismissed: true }),
      reset: () => set({ photoNudgeDismissed: false }),
    }),
    {
      name: 'profile-nudge-v1',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
