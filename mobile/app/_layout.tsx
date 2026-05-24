import '../global.css';
import { useEffect, useState } from 'react';
import { Stack, SplashScreen } from 'expo-router';
import { QueryClientProvider } from '@tanstack/react-query';
import {
  useFonts as useDosis,
  Dosis_400Regular,
  Dosis_500Medium,
  Dosis_600SemiBold,
  Dosis_700Bold,
  Dosis_800ExtraBold,
} from '@expo-google-fonts/dosis';
import {
  useFonts as useInter,
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
} from '@expo-google-fonts/inter';
import { Sentry, initSentry, SentryErrorBoundary } from '~/lib/sentry';
import { initFirebase } from '~/lib/firebase';
import { initI18n } from '~/lib/i18n';
import { SessionProvider } from '~/features/auth/SessionContext';
import { queryClient } from '~/lib/query-client';
import { useRegisterFcmToken } from '~/features/push/hooks/useRegisterFcmToken';
import { useNotificationTapHandler } from '~/features/push/hooks/useNotificationTapHandler';
import { PushToast } from '~/features/push/components/PushToast';
import { ConfirmProvider } from '~/components/ui/ConfirmDialog';
import { ToastHost } from '~/components/ui/Toast';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

SplashScreen.preventAutoHideAsync().catch(() => {});

function PushBootstrap() {
  useRegisterFcmToken();
  useNotificationTapHandler();
  return null;
}

function RootLayout() {
  const [dosisLoaded] = useDosis({
    Dosis_400Regular,
    Dosis_500Medium,
    Dosis_600SemiBold,
    Dosis_700Bold,
    Dosis_800ExtraBold,
  });
  const [interLoaded] = useInter({
    Inter_400Regular,
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  // GDPR opt-out gate: `initSentry()` and `initFirebase()` read
  // `useTelemetryStore.getState()` synchronously and short-circuit when
  // `crashReportsEnabled` / `analyticsEnabled` are false. The persist
  // middleware rehydrates ASYNCHRONOUSLY from AsyncStorage — calling init at
  // module-eval time means we read the in-memory defaults (`false`) instead
  // of the user's saved preference, then either never honour their opt-IN
  // or, worse, race the rehydrate and get inconsistent behaviour per launch.
  // Await rehydrate first, THEN init telemetry SDKs.
  const [telemetryReady, setTelemetryReady] = useState(false);
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        await useTelemetryStore.persist.rehydrate();
      } catch (e) {
        // Rehydrate is best-effort — a corrupted store should not block boot.
        console.warn('[boot] telemetry rehydrate failed', e);
      }
      if (cancelled) return;
      initSentry();
      initFirebase();
      initI18n();
      setTelemetryReady(true);
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const ready = dosisLoaded && interLoaded && telemetryReady;

  useEffect(() => {
    if (ready) SplashScreen.hideAsync().catch(() => {});
  }, [ready]);

  if (!ready) return null;

  return (
    <SentryErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <SessionProvider>
          <ConfirmProvider>
            <PushBootstrap />
            <Stack screenOptions={{ headerShown: false }} />
            {/* Top-anchored notification surfaces. Order: PushToast (FCM
                foreground) below ToastHost (in-app) so in-app feedback wins
                z-order when both fire at once. */}
            <PushToast />
            <ToastHost />
          </ConfirmProvider>
        </SessionProvider>
      </QueryClientProvider>
    </SentryErrorBoundary>
  );
}

export default Sentry.wrap(RootLayout);
