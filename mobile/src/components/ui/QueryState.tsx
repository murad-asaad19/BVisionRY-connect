import { ReactNode } from 'react';
import { View, Text, Pressable, ActivityIndicator } from 'react-native';
import { colors } from '~/theme/colors';
import { Banner } from '~/components/ui/Banner';

type Props<T> = {
  query: {
    isLoading: boolean;
    isError: boolean;
    error?: Error | null;
    data: T | undefined;
    refetch: () => void;
  };
  loadingFallback?: ReactNode;
  emptyFallback?: ReactNode;
  isEmpty?: (data: T) => boolean;
  /** Copy shown when `isEmpty` returns true and no explicit `emptyFallback` is provided. */
  emptyText?: string;
  children: (data: T) => ReactNode;
};

export function QueryState<T>({
  query,
  loadingFallback,
  emptyFallback,
  isEmpty,
  emptyText,
  children,
}: Props<T>) {
  if (query.isLoading) {
    return (
      <>
        {loadingFallback ?? (
          <View className="py-12 items-center" testID="query-state-loading">
            <ActivityIndicator color={colors.navy} />
          </View>
        )}
      </>
    );
  }

  if (query.isError) {
    return (
      <View className="py-12 px-6 items-center" testID="query-state-error">
        <Text className="text-danger-text text-center mb-2" testID="query-state-error-message">
          Something went wrong.
        </Text>
        {query.error?.message && (
          <Text className="text-muted text-xs text-center mb-4">{query.error.message}</Text>
        )}
        <Pressable
          testID="query-state-retry"
          onPress={query.refetch}
          className="bg-white border border-border px-4 py-2 rounded-lg"
        >
          <Text className="text-body">Retry</Text>
        </Pressable>
      </View>
    );
  }

  if (query.data === undefined) {
    return null; // shouldn't happen if not loading and not erroring, but type-safety guard
  }

  if (isEmpty && isEmpty(query.data)) {
    if (emptyFallback) return <>{emptyFallback}</>;
    return (
      <View className="py-6 px-4" testID="query-state-empty">
        <Banner variant="muted">{emptyText ?? 'Nothing here yet'}</Banner>
      </View>
    );
  }

  return <>{children(query.data)}</>;
}
