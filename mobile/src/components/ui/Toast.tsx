import { useEffect, useCallback } from 'react';
import { Pressable, Text, View } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSpring,
  runOnJS,
} from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CheckCircle2, XCircle, Info, X as XIcon } from 'lucide-react-native';
import type { LucideIcon } from 'lucide-react-native';
import { create } from 'zustand';
import { colors } from '~/theme/colors';

export type ToastKind = 'success' | 'error' | 'info';

export type ToastAction = {
  label: string;
  onPress: () => void;
};

export type ToastInput = {
  kind: ToastKind;
  message: string;
  durationMs?: number;
  action?: ToastAction;
};

type ToastItem = ToastInput & {
  id: string;
};

type State = {
  toasts: ToastItem[];
  show: (input: ToastInput) => string;
  dismiss: (id: string) => void;
};

const MAX_STACK = 3;
const DEFAULT_DURATION_MS = 3000;

let counter = 0;
function nextId(): string {
  counter += 1;
  return `toast-${Date.now()}-${counter}`;
}

const useToastStore = create<State>((set) => ({
  toasts: [],
  show: (input) => {
    const id = nextId();
    set((s) => {
      const next = [...s.toasts, { ...input, id }];
      // Cap the stack — drop the oldest when a new one would overflow.
      return { toasts: next.length > MAX_STACK ? next.slice(next.length - MAX_STACK) : next };
    });
    return id;
  },
  dismiss: (id) =>
    set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
}));

/**
 * Hook for in-component usage. Returns a stable object with the kind-specific
 * shortcuts plus the generic `show(...)` for custom durations/actions.
 */
export function useToast() {
  return {
    show: (input: ToastInput) => useToastStore.getState().show(input),
    success: (message: string) =>
      useToastStore.getState().show({ kind: 'success', message }),
    error: (message: string) =>
      useToastStore.getState().show({ kind: 'error', message }),
    info: (message: string) => useToastStore.getState().show({ kind: 'info', message }),
  };
}

/**
 * Imperative variant — usable from service modules / event handlers outside
 * React. Same surface as the hook.
 */
export const toast = {
  show: (input: ToastInput) => useToastStore.getState().show(input),
  success: (message: string) =>
    useToastStore.getState().show({ kind: 'success', message }),
  error: (message: string) =>
    useToastStore.getState().show({ kind: 'error', message }),
  info: (message: string) => useToastStore.getState().show({ kind: 'info', message }),
  dismiss: (id: string) => useToastStore.getState().dismiss(id),
};

const KIND_CLASSES: Record<
  ToastKind,
  { bg: string; border: string; text: string; iconColor: string; Icon: LucideIcon }
> = {
  success: {
    bg: 'bg-success-bg',
    border: 'border-success-border',
    text: 'text-success-text',
    iconColor: colors.success,
    Icon: CheckCircle2,
  },
  error: {
    bg: 'bg-danger-bg',
    border: 'border-danger-border',
    text: 'text-danger-text',
    iconColor: colors.danger,
    Icon: XCircle,
  },
  info: {
    bg: 'bg-info-bg',
    border: 'border-info-border',
    text: 'text-info-text',
    iconColor: colors.info,
    Icon: Info,
  },
};

/**
 * Mount once at the app root. Top-anchored stack — toasts slide in from
 * above, respect SafeArea, and auto-dismiss after their `durationMs`.
 */
export function ToastHost() {
  const toasts = useToastStore((s) => s.toasts);
  if (toasts.length === 0) return null;
  return (
    <SafeAreaView
      edges={['top']}
      pointerEvents="box-none"
      className="absolute top-0 left-0 right-0 z-50"
    >
      <View pointerEvents="box-none" className="px-4 pt-2">
        {toasts.map((t) => (
          <ToastRow key={t.id} item={t} />
        ))}
      </View>
    </SafeAreaView>
  );
}

function ToastRow({ item }: { item: ToastItem }) {
  const dismiss = useToastStore((s) => s.dismiss);
  const handleDismiss = useCallback(() => dismiss(item.id), [dismiss, item.id]);

  // Slide-down + fade-in entry; fade-out on dismiss is best-effort (the
  // store drops the item immediately, so we just play the entry animation).
  const translateY = useSharedValue(-24);
  const opacity = useSharedValue(0);

  useEffect(() => {
    opacity.value = withTiming(1, { duration: 180 });
    translateY.value = withSpring(0, { damping: 18, stiffness: 220 });
  }, [opacity, translateY]);

  useEffect(() => {
    const duration = item.durationMs ?? DEFAULT_DURATION_MS;
    if (duration <= 0) return;
    const timer = setTimeout(() => {
      // Run dismissal on JS thread — `dismiss` is a JS-side store mutation.
      runOnJS(handleDismiss)();
    }, duration);
    return () => clearTimeout(timer);
  }, [item.durationMs, handleDismiss]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  const palette = KIND_CLASSES[item.kind];
  const { Icon } = palette;

  return (
    <Animated.View style={animatedStyle} className="mt-2">
      <Pressable
        testID={`toast-${item.kind}`}
        onPress={handleDismiss}
        accessibilityRole="alert"
        accessibilityLabel={item.message}
        className={`rounded-xl border px-3 py-2.5 flex-row items-start gap-2 ${palette.bg} ${palette.border}`}
      >
        <View className="mt-0.5">
          <Icon size={18} color={palette.iconColor} />
        </View>
        <View className="flex-1">
          <Text className={`font-body-medium text-body-md ${palette.text}`}>{item.message}</Text>
          {item.action ? (
            <Pressable
              onPress={(e) => {
                // Stop propagation so tapping the action doesn't also dismiss.
                e.stopPropagation();
                item.action!.onPress();
                handleDismiss();
              }}
              hitSlop={6}
              className="mt-1.5 self-start"
            >
              <Text className={`font-display-bold text-display-xs uppercase ${palette.text}`}>
                {item.action.label}
              </Text>
            </Pressable>
          ) : null}
        </View>
        <Pressable
          onPress={(e) => {
            e.stopPropagation();
            handleDismiss();
          }}
          hitSlop={8}
          accessibilityRole="button"
          accessibilityLabel="Dismiss"
          className="ml-1"
        >
          <XIcon size={16} color={palette.iconColor} />
        </Pressable>
      </Pressable>
    </Animated.View>
  );
}
