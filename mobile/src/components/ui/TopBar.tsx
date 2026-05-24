import { useContext, useEffect } from 'react';
import { View, Text, Pressable, BackHandler } from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { ChevronLeft } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { colors } from '~/theme/colors';

type Action = {
  icon: ReactNode;
  onPress: () => void;
  /** Required for screen-readers and to satisfy the icon-button audit pass. */
  accessibilityLabel?: string;
  /** Back-compat alias for `accessibilityLabel`. */
  label?: string;
  testID?: string;
};

export type TopBarSize = 'md' | 'lg';

type Props = {
  title: string;
  /** Optional smaller subtitle rendered below the title. */
  subtitle?: string;
  /** Title size — `md` (default, 16px) for tab/detail screens, `lg` (20px) for marketing/onboarding. */
  size?: TopBarSize;
  /** Optional testID applied to the title Text. */
  titleTestID?: string;
  actions?: Action[];
  /** Arbitrary node rendered left of the title block (e.g. an Avatar in the chat header). */
  leading?: ReactNode;
  /**
   * When `true`, renders a back chevron that calls `router.back()` and intercepts
   * the Android hardware back button. Pass a function to override the handler.
   */
  back?: boolean | (() => void);
};

const TITLE_CLASS: Record<TopBarSize, string> = {
  md: 'font-display-bold text-display-md text-navy',
  lg: 'font-display-bold text-display-lg text-navy',
};

export function TopBar({
  title,
  subtitle,
  size = 'md',
  titleTestID,
  actions,
  leading,
  back,
}: Props) {
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
      className="bg-white px-gutter pb-2 border-b border-border flex-row items-center justify-between"
    >
      <View className="flex-row items-center gap-2 flex-1 min-w-0">
        {backHandler ? (
          <Pressable
            testID="topbar-back"
            onPress={backHandler}
            accessibilityRole="button"
            accessibilityLabel="Back"
            // 44pt minimum touch target around the 20px chevron.
            hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
            className="w-7 h-7 items-center justify-center"
          >
            <ChevronLeft size={20} color={colors.navy} />
          </Pressable>
        ) : null}
        {leading}
        <View className="flex-1 min-w-0">
          <Text testID={titleTestID} numberOfLines={1} className={TITLE_CLASS[size]}>
            {title}
          </Text>
          {subtitle ? (
            <Text numberOfLines={1} className="font-body text-body-sm text-muted">
              {subtitle}
            </Text>
          ) : null}
        </View>
      </View>
      {actions?.length ? (
        <View className="flex-row items-center gap-1">
          {actions.map((a, i) => (
            <Pressable
              key={i}
              testID={a.testID}
              onPress={a.onPress}
              accessibilityRole="button"
              accessibilityLabel={a.accessibilityLabel ?? a.label}
              // Each icon button gets a 44pt touch target.
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
              className="w-11 h-11 items-center justify-center"
            >
              {a.icon}
            </Pressable>
          ))}
        </View>
      ) : null}
    </View>
  );
}
