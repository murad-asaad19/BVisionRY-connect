// Metro auto-resolves to .native.ts on iOS/Android and .web.ts on web.
export { initFirebase, getFcmToken, onForegroundMessage } from './index.native';
