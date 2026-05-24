import type { ReactNode } from 'react';
import { render, type RenderOptions } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

/**
 * Render helper that wires up a fresh React Query client around the component
 * under test. Components which use `useQuery` / `useMutation` need a provider
 * in the tree — the real app mounts one at the root, but unit tests get a
 * disposable client with retries disabled so a failed mocked fetch surfaces
 * immediately instead of retrying.
 */
export function renderWithProviders(
  ui: React.ReactElement,
  options?: Omit<RenderOptions, 'wrapper'> & { client?: QueryClient }
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
  return { client, ...render(ui, { ...options, wrapper }) };
}
