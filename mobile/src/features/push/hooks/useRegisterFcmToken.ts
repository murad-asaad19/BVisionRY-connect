import { useEffect } from 'react';
import { Platform } from 'react-native';
import { useAuthSession } from '~/features/auth/SessionContext';
import { getFcmToken } from '~/lib/firebase';
import { registerDeviceToken } from '~/features/push/services/push.service';
import type { DevicePlatform } from '~/features/push/services/push.service';

function platformValue(): DevicePlatform | null {
  if (Platform.OS === 'android') return 'android';
  if (Platform.OS === 'ios') return 'ios';
  return null; // web: skip
}

/**
 * Captures the FCM token once a session is established and upserts it via RPC.
 * Web is a no-op. Errors are swallowed (logged) to avoid blocking auth flows.
 */
export function useRegisterFcmToken() {
  const { session } = useAuthSession();
  const userId = session?.user.id;

  useEffect(() => {
    if (!userId) return;
    const platform = platformValue();
    if (!platform) return;
    (async () => {
      try {
        const token = await getFcmToken();
        if (!token) return;
        await registerDeviceToken(token, platform);
      } catch (e) {
        console.warn('[push] register token failed', e);
      }
    })();
  }, [userId]);
}
