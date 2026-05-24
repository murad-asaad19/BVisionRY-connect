import type { ReactNode } from 'react';
import { renderHook, type RenderHookOptions } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

/**
 * Hook render helper that wires up a fresh React Query client around the
 * hook under test. Pass `client` in options to share a client across the
 * whole test (e.g. to inspect cache state); omit it for a clean isolated
 * client per call. Retries are disabled so a failed mocked fetch surfaces
 * immediately instead of retrying.
 */
export function renderHookWithProviders<R, P>(
  hook: (props: P) => R,
  options?: Omit<RenderHookOptions<P>, 'wrapper'> & { client?: QueryClient }
) {
  const client =
    options?.client ??
    new QueryClient({
      defaultOptions: {
        queries: { retry: false },
        mutations: { retry: false },
      },
    });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return { client, ...renderHook(hook, { ...options, wrapper }) };
}
