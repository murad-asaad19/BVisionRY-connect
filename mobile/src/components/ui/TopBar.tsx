import { useContext, useEffect } from 'react';
import { View, Text, Pressable, BackHandler } from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import type { ReactNode } from 'react';

type Action = {
  icon: ReactNode;
  onPress: () => void;
  accessibilityLabel: string;
  testID?: string;
};

type Props = {
  title: string;
  /** Optional testID applied to the title Text. */
  titleTestID?: string;
  actions?: Action[];
  leading?: ReactNode;
  /**
   * When `true`, renders a back chevron that calls `router.back()` and intercepts
   * the Android hardware back button. Pass a function to override the handler.
   */
  back?: boolean | (() => void);
};

export function TopBar({ title, titleTestID, actions, leading, back }: Props) {
  // Read insets via context directly so the component degrades gracefully (top inset = 0)
  // when no SafeAreaProvider is mounted (tests, Storybook). Expo Router wires the provider
  // in production via its Stack/Tabs roots.
  const insets = useContext(SafeAreaInsetsContext) ?? { top: 0, bottom: 0, left: 0, right: 0 };
  const router = useRouter();
  const backHandler = back ? (typeof back === 'function' ? back : () => router.back()) : null;

  useEffect(() => {
    if (!backHandler) return;
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      backHandler();
      return true;
    });
    return () => sub.remove();
  }, [backHandler]);

  return (
    <View
      style={{ paddingTop: insets.top + 6 }}
      className="bg-white px-4 pb-2.5 border-b border-border flex-row items-center justify-between"
    >
      <View className="flex-row items-center gap-2 flex-1 min-w-0">
        {backHandler ? (
          <Pressable
            testID="topbar-back"
            onPress={backHandler}
            accessibilityRole="button"
            accessibilityLabel="Back"
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          >
            <Text className="font-display-bold text-[20px] text-navy">‹</Text>
          </Pressable>
        ) : null}
        {leading}
        <Text
          testID={titleTestID}
          numberOfLines={1}
          className="font-display-bold text-[16px] text-navy flex-1"
        >
          {title}
        </Text>
      </View>
      {actions?.length ? (
        <View className="flex-row gap-3">
          {actions.map((a, i) => (
            <Pressable
              key={i}
              testID={a.testID}
              onPress={a.onPress}
              accessibilityRole="button"
              accessibilityLabel={a.accessibilityLabel}
            >
              {a.icon}
            </Pressable>
          ))}
        </View>
      ) : null}
    </View>
  );
}
