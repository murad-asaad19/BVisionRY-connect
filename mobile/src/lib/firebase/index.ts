// Cross-platform fallback for tools that don't honor platform extensions
// (Jest, tsc). At runtime, Metro/Expo auto-resolves to `./index.native.ts` on
// iOS/Android and `./index.web.ts` on web — this file is never loaded by the
// app. We re-export the web (no-op) implementation rather than the native one
// because the native version imports `@react-native-firebase/*` packages that
// crash when evaluated outside a RN runtime.
//
// We export a structural `RemoteMessage` type that matches the FCM payload
// shape so consumers (which import from `~/lib/firebase`) get useful types
// in tsc/Jest without depending on `@react-native-firebase/messaging`.

export type RemoteMessage = {
  notification?: {
    title?: string;
    body?: string;
  };
  data?: Record<string, string | undefined>;
};

export type ForegroundMessageHandler = (message: RemoteMessage) => void;

export { initFirebase, getFcmToken } from './index.web';

// Re-export with a typed handler signature so consumers retain autocomplete.
import { onForegroundMessage as onForegroundMessageImpl } from './index.web';
export const onForegroundMessage: (handler: ForegroundMessageHandler) => () => void =
  onForegroundMessageImpl as unknown as (handler: ForegroundMessageHandler) => () => void;
