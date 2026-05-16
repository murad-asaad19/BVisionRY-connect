import '../global.css';
import { useEffect } from 'react';
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
  useFonts as useOverlock,
  Overlock_400Regular,
  Overlock_700Bold,
} from '@expo-google-fonts/overlock';
import { Sentry, initSentry } from '~/lib/sentry';
import { initFirebase } from '~/lib/firebase';
import { initI18n } from '~/lib/i18n';
import { SessionProvider } from '~/features/auth/SessionContext';
import { queryClient } from '~/lib/query-client';
import { useRegisterFcmToken } from '~/features/push/hooks/useRegisterFcmToken';
import { useNotificationTapHandler } from '~/features/push/hooks/useNotificationTapHandler';
import { PushToast } from '~/features/push/components/PushToast';

initSentry();
initFirebase();
initI18n();

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
  const [overlockLoaded] = useOverlock({
    Overlock_400Regular,
    Overlock_700Bold,
  });

  const ready = dosisLoaded && overlockLoaded;

  useEffect(() => {
    if (ready) SplashScreen.hideAsync().catch(() => {});
  }, [ready]);

  if (!ready) return null;

  return (
    <QueryClientProvider client={queryClient}>
      <SessionProvider>
        <PushBootstrap />
        <PushToast />
        <Stack screenOptions={{ headerShown: false }} />
      </SessionProvider>
    </QueryClientProvider>
  );
}

export default Sentry.wrap(RootLayout);
