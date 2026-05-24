import '@testing-library/react-native';

// ─── react-native-reanimated ────────────────────────────────────────────────
// Reanimated ships a Jest mock that stubs the worklet/animation surface so
// components which import the library render synchronously in tests.
jest.mock('react-native-reanimated', () => require('react-native-reanimated/mock'));

// ─── react-native-gesture-handler ───────────────────────────────────────────
// Gesture handler's native bindings aren't available in Jest. Replace the
// surface with plain Views / no-op components so screens that wrap content in
// `GestureHandlerRootView` or use `Swipeable` still mount.
jest.mock('react-native-gesture-handler', () => {
  const View = require('react-native').View;
  return {
    __esModule: true,
    Swipeable: View,
    DrawerLayout: View,
    State: {},
    PanGestureHandler: View,
    TapGestureHandler: View,
    LongPressGestureHandler: View,
    RotationGestureHandler: View,
    PinchGestureHandler: View,
    FlingGestureHandler: View,
    NativeViewGestureHandler: View,
    ScrollView: require('react-native').ScrollView,
    GestureHandlerRootView: ({ children }: { children: React.ReactNode }) => children,
    gestureHandlerRootHOC: (c: unknown) => c,
    Directions: {},
  };
});

// ─── @react-native-async-storage/async-storage ──────────────────────────────
// The package ships an official Jest mock that stores values in an in-memory
// Map so hooks/stores which persist to AsyncStorage exercise the real code
// path without hitting the platform module.
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

// ─── react-native-safe-area-context ─────────────────────────────────────────
// The native module isn't available in Jest. Provide zero-inset stubs so
// components that read insets (TopBar, screens with bottom-tab spacing)
// render without throwing.
jest.mock('react-native-safe-area-context', () => {
  const inset = { top: 0, right: 0, bottom: 0, left: 0 };
  const frame = { width: 320, height: 640, x: 0, y: 0 };
  return {
    __esModule: true,
    SafeAreaProvider: ({ children }: { children: React.ReactNode }) => children,
    SafeAreaConsumer: ({ children }: { children: (i: typeof inset) => React.ReactNode }) =>
      children(inset),
    SafeAreaView: ({ children }: { children: React.ReactNode }) => children,
    SafeAreaInsetsContext: {
      Consumer: ({ children }: { children: (i: typeof inset) => React.ReactNode }) =>
        children(inset),
    },
    useSafeAreaInsets: () => inset,
    useSafeAreaFrame: () => frame,
  };
});

// ─── ~/lib/firebase ─────────────────────────────────────────────────────────
// The real module pulls in `@react-native-firebase/*` which crashes outside
// the RN runtime. The web stub already returns no-ops; tests just need the
// async surface to resolve predictably.
jest.mock('~/lib/firebase', () => ({
  __esModule: true,
  initFirebase: jest.fn(),
  getFcmToken: jest.fn().mockResolvedValue('test-fcm-token'),
  onForegroundMessage: jest.fn(() => () => {}),
}));

// ─── ~/lib/sentry ───────────────────────────────────────────────────────────
// Sentry init touches native bridges; stub the surface and keep `redactTokens`
// as a passthrough so tests that exercise it still pass through unchanged.
jest.mock('~/lib/sentry', () => ({
  __esModule: true,
  initSentry: jest.fn(),
  redactTokens: (s: string) => s,
  Sentry: { captureException: jest.fn(), captureMessage: jest.fn() },
}));

// ─── @react-native-community/netinfo ────────────────────────────────────────
// NetInfo's native module isn't available in Jest. Stub the surface so
// network-aware code (refetch-on-reconnect, banners, etc.) renders without
// throwing. The `addEventListener` mock returns an unsubscribe fn so callers
// that wire it into `useEffect` cleanups still work.
//
// `virtual: true` because the package may not be hoisted into mobile's own
// `node_modules` (it can land at the workspace root). Without the flag,
// jest.mock fails resolution and tears down every suite.
jest.mock(
  '@react-native-community/netinfo',
  () => ({
    __esModule: true,
    default: {
      addEventListener: jest.fn(() => () => {}),
      fetch: jest.fn().mockResolvedValue({ isConnected: true }),
    },
  }),
  { virtual: true }
);
