import type { ReactNode } from 'react';
import { render, type RenderOptions } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

/**
 * Render helper that wraps the tree in a SafeAreaProvider with explicit
 * initialMetrics so children which read insets via `useSafeAreaInsets` (or
 * `<SafeAreaInsetsContext.Consumer>`) get zero-inset values synchronously.
 *
 * Most tests don't need this because `tests/setup.ts` mocks
 * `react-native-safe-area-context` globally. Keep this helper for the rare
 * spec that wants to unmock the module and exercise the real provider.
 */
export function renderWithSafeArea(
  ui: React.ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) {
  const wrapper = ({ children }: { children: ReactNode }) => (
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 320, height: 640 },
        insets: { top: 0, bottom: 0, left: 0, right: 0 },
      }}
    >
      {children}
    </SafeAreaProvider>
  );
  return render(ui, { ...options, wrapper });
}
