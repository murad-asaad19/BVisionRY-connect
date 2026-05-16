import * as Sentry from '@sentry/react-native';
import { env } from '~/lib/env';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

let initialized = false;

export function initSentry() {
  if (initialized) return;
  if (!env.SENTRY_DSN) {
    return; // No-op if DSN is unset
  }
  // Best-effort opt-out: read the persisted pref synchronously. If the store
  // hasn't rehydrated from AsyncStorage yet, this returns the default (true).
  // Pref changes via Settings take effect on the NEXT app launch.
  if (!useTelemetryStore.getState().crashReportsEnabled) {
    return;
  }
  Sentry.init({
    dsn: env.SENTRY_DSN,
    environment: env.SENTRY_ENV,
    enableNativeCrashHandling: true,
    tracesSampleRate: 0.2,
  });
  initialized = true;
}

export { Sentry };
