import { focusManager, onlineManager, QueryClient } from '@tanstack/react-query';
import { AppState, Platform, type AppStateStatus } from 'react-native';
import NetInfo from '@react-native-community/netinfo';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000, // 30s — profile data is rarely contested
      refetchOnWindowFocus: false,
      retry: 1,
    },
    mutations: {
      retry: 0,
    },
  },
});

// Wire React Query's online/focus managers to RN-native signals so cached
// queries refetch when the app regains connectivity or returns to foreground.
// Web uses the built-in browser listeners — skip there.
if (Platform.OS !== 'web') {
  onlineManager.setEventListener((setOnline) => {
    const sub = NetInfo.addEventListener((state) => {
      setOnline(!!state.isConnected);
    });
    return () => sub();
  });

  // Hold the subscription in module scope. RN's `AppState.addEventListener`
  // returns an `EmitterSubscription` with a `.remove()` method — we don't
  // currently dispose, but dropping the return value entirely makes a future
  // HMR cleanup impossible to wire without re-evaluating this module first.
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const appStateSub = AppState.addEventListener('change', (status: AppStateStatus) => {
    focusManager.setFocused(status === 'active');
  });
}
