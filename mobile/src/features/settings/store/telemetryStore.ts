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
 * Defaults are intentionally `false` (opt-OUT) for GDPR safety. The persist
 * middleware rehydrates from AsyncStorage asynchronously, so any consumer
 * reading `getState()` before rehydration completes sees `false` and skips
 * data collection — failing closed is the correct behaviour for telemetry.
 *
 * Init paths that read these prefs (`initSentry()`, `initFirebase()`) MUST
 * await rehydration before reading state to honour the user's saved choice:
 *
 *   await useTelemetryStore.persist.rehydrate();
 *   const { analyticsEnabled, crashReportsEnabled } = useTelemetryStore.getState();
 *
 * Once rehydration completes the user's saved preference overrides the
 * defaults. Toggling at runtime persists immediately but SDK changes only
 * take effect on next launch — acceptable for v1.
 *
 * Note: `signOut()` in auth.service.ts resets these back to `{false, false}`
 * so the next user on the device starts opted-out and must explicitly opt in
 * via Settings. Persisting the prior user's telemetry preference across a
 * sign-out would be a GDPR violation.
 */
export const useTelemetryStore = create<State>()(
  persist(
    (set) => ({
      analyticsEnabled: false,
      crashReportsEnabled: false,
      setAnalytics: (v) => set({ analyticsEnabled: v }),
      setCrashReports: (v) => set({ crashReportsEnabled: v }),
    }),
    { name: 'telemetry-prefs', storage: createJSONStorage(() => AsyncStorage) }
  )
);
