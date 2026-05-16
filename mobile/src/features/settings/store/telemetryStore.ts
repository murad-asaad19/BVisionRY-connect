import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

type State = {
  analyticsEnabled: boolean;
  crashReportsEnabled: boolean;
  setAnalytics: (v: boolean) => void;
  setCrashReports: (v: boolean) => void;
};

/**
 * Telemetry opt-out preferences.
 *
 * NOTE: These prefs are read at app launch in `initSentry()` / `initFirebase()`.
 * Toggling at runtime persists immediately but the SDK changes only take effect
 * on next launch — this is acceptable for v1.
 */
export const useTelemetryStore = create<State>()(
  persist(
    (set) => ({
      analyticsEnabled: true,
      crashReportsEnabled: true,
      setAnalytics: (v) => set({ analyticsEnabled: v }),
      setCrashReports: (v) => set({ crashReportsEnabled: v }),
    }),
    { name: 'telemetry-prefs', storage: createJSONStorage(() => AsyncStorage) }
  )
);
