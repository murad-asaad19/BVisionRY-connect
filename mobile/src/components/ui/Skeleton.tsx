import { useEffect } from 'react';
import { View } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import type { DimensionValue } from 'react-native';

type SkeletonProps = {
  w?: DimensionValue;
  h?: DimensionValue;
  radius?: number;
  className?: string;
};

/**
 * Single animated pulsing block. Reuses one `useSharedValue` per instance —
 * cheap enough that we don't bother sharing across mounts. Driven on the UI
 * thread by reanimated so the JS thread is free to receive query results.
 */
export function Skeleton({ w = '100%', h = 12, radius = 8, className }: SkeletonProps) {
  const opacity = useSharedValue(0.6);

  useEffect(() => {
    opacity.value = withRepeat(
      withTiming(1, { duration: 800, easing: Easing.inOut(Easing.ease) }),
      -1,
      true
    );
  }, [opacity]);

  const style = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }));

  return (
    <Animated.View
      style={[{ width: w, height: h, borderRadius: radius }, style]}
      className={`bg-slate-100 ${className ?? ''}`}
    />
  );
}

// ── Composite skeletons ─────────────────────────────────────────────────────
// Each mirrors the geometry of the real card so the loading state doesn't
// jump when data arrives. Defaults to `count={1}`; lists usually pass 4-6.

type ListProps = { count?: number };

function Column({ count = 1, children }: { count?: number; children: React.ReactNode }) {
  return (
    <View>
      {Array.from({ length: count }).map((_, i) => (
        <View key={i} className={i === 0 ? '' : 'mt-3'}>
          {children}
        </View>
      ))}
    </View>
  );
}

/** Mirrors `UserCard` — 38px avatar + name/handle/headline stack. */
export function SkeletonUserCard({ count = 1 }: ListProps) {
  return (
    <Column count={count}>
      <View className="bg-white border border-border rounded-[14px] p-3 mx-gutter">
        <View className="flex-row items-start gap-2.5">
          <Skeleton w={38} h={38} radius={19} />
          <View className="flex-1">
            <Skeleton w="50%" h={12} />
            <View className="mt-1.5">
              <Skeleton w="35%" h={10} />
            </View>
            <View className="mt-2">
              <Skeleton w="90%" h={10} />
            </View>
            <View className="mt-1">
              <Skeleton w="70%" h={10} />
            </View>
          </View>
        </View>
      </View>
    </Column>
  );
}

/** Mirrors `OpportunityCard` — kind chip row, title, 3-line body, tags, author. */
export function SkeletonOpportunityCard({ count = 1 }: ListProps) {
  return (
    <Column count={count}>
      <View className="bg-white border border-border rounded-[14px] p-3 mx-gutter">
        <View className="flex-row gap-2">
          <Skeleton w={64} h={16} radius={10} />
          <Skeleton w={80} h={16} radius={10} />
        </View>
        <View className="mt-2.5">
          <Skeleton w="85%" h={14} />
        </View>
        <View className="mt-2">
          <Skeleton w="100%" h={10} />
        </View>
        <View className="mt-1">
          <Skeleton w="95%" h={10} />
        </View>
        <View className="mt-1">
          <Skeleton w="80%" h={10} />
        </View>
        <View className="flex-row items-center gap-2 mt-3">
          <Skeleton w={32} h={32} radius={16} />
          <View className="flex-1">
            <Skeleton w="40%" h={10} />
            <View className="mt-1">
              <Skeleton w="55%" h={10} />
            </View>
          </View>
        </View>
      </View>
    </Column>
  );
}

/** Mirrors `ConversationListRow` — 48px avatar + name/handle/preview stack. */
export function SkeletonConversationRow({ count = 1 }: ListProps) {
  return (
    <Column count={count}>
      <View className="flex-row items-center bg-white border border-border rounded-xl px-4 py-3 mx-gutter">
        <Skeleton w={48} h={48} radius={24} />
        <View className="ml-4 flex-1">
          <Skeleton w="55%" h={12} />
          <View className="mt-1.5">
            <Skeleton w="30%" h={10} />
          </View>
          <View className="mt-1.5">
            <Skeleton w="85%" h={10} />
          </View>
        </View>
      </View>
    </Column>
  );
}

/** Mirrors `IntroListRow` — 48px avatar + name/handle/two-line note. */
export function SkeletonIntroRow({ count = 1 }: ListProps) {
  return (
    <Column count={count}>
      <View className="flex-row items-start bg-white border border-border rounded-xl px-4 py-3 mx-gutter">
        <Skeleton w={48} h={48} radius={24} />
        <View className="ml-4 flex-1">
          <View className="flex-row items-center justify-between">
            <Skeleton w="40%" h={12} />
            <Skeleton w={56} h={14} radius={10} />
          </View>
          <View className="mt-1.5">
            <Skeleton w="30%" h={10} />
          </View>
          <View className="mt-2">
            <Skeleton w="95%" h={10} />
          </View>
          <View className="mt-1">
            <Skeleton w="80%" h={10} />
          </View>
        </View>
      </View>
    </Column>
  );
}

/**
 * Mirrors `ProfileView` — hero block + a couple of SectionCard-shaped panels.
 * `count` here repeats the section panels (the hero is always rendered once).
 */
export function SkeletonProfile({ count = 3 }: ListProps) {
  return (
    <View>
      {/* Hero */}
      <View className="bg-white px-gutter pt-6 pb-5">
        <View className="items-center">
          <Skeleton w={96} h={96} radius={48} />
          <View className="mt-3">
            <Skeleton w={180} h={16} />
          </View>
          <View className="mt-2">
            <Skeleton w={120} h={10} />
          </View>
        </View>
      </View>
      {/* Section panels */}
      {Array.from({ length: count }).map((_, i) => (
        <View
          key={i}
          className="bg-white mx-gutter mt-3 rounded-xl border border-border p-card-lg"
        >
          <Skeleton w={80} h={10} />
          <View className="mt-3">
            <Skeleton w="100%" h={10} />
          </View>
          <View className="mt-1.5">
            <Skeleton w="90%" h={10} />
          </View>
          <View className="mt-1.5">
            <Skeleton w="70%" h={10} />
          </View>
        </View>
      ))}
    </View>
  );
}
