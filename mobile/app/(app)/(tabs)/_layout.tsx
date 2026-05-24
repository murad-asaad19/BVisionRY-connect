import { Tabs } from 'expo-router';
import { useMemo } from 'react';
import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import type { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import {
  Home,
  Inbox as InboxIcon,
  Users,
  Briefcase,
  MessageSquare,
  type LucideIcon,
} from 'lucide-react-native';
import { useUnreadIntros } from '~/features/intros/hooks/useUnreadIntros';
import { useUnreadCounts } from '~/features/chat/hooks/useUnreadCounts';
import { colors } from '~/theme/colors';

const ICONS: Record<string, LucideIcon> = {
  home: Home,
  inbox: InboxIcon,
  network: Users,
  opportunities: Briefcase,
  chats: MessageSquare,
};

type TabBadgeMap = Record<string, number | undefined>;

function CustomTabBar({
  state,
  navigation,
  badges,
}: BottomTabBarProps & { badges: TabBadgeMap }) {
  const { t } = useTranslation();
  return (
    // NativeWind v5 preview occasionally fails to compile layout-critical
    // utilities on the web target, leaving the tab bar stacked vertically
    // and the page content empty. Belt-and-suspenders: inline `style` for
    // the flex direction + background so the layout is correct regardless
    // of whether NativeWind's web compilation produces the matching CSS.
    <View
      className="bg-white border-t border-border flex-row justify-around py-2"
      style={{
        flexDirection: 'row',
        justifyContent: 'space-around',
        paddingVertical: 8,
        backgroundColor: colors.white,
        borderTopWidth: 1,
        borderTopColor: colors.border,
      }}
    >
      {state.routes.map((route, i) => {
        const focused = state.index === i;
        const Icon = ICONS[route.name];
        const label = t(`nav.tabs.${route.name}`, { defaultValue: route.name });
        const badgeCount = badges[route.name];
        const showBadge = typeof badgeCount === 'number' && badgeCount > 0;
        const tint = focused ? colors.navy : colors.muted;
        return (
          <Pressable
            key={route.key}
            onPress={() => {
              const e = navigation.emit({
                type: 'tabPress',
                target: route.key,
                canPreventDefault: true,
              });
              if (!focused && !e.defaultPrevented) navigation.navigate(route.name);
            }}
            accessibilityRole="button"
            accessibilityLabel={label}
            accessibilityState={{ selected: focused }}
            className="items-center flex-1"
            style={{ flex: 1, alignItems: 'center' }}
          >
            <View>
              {Icon ? (
                <Icon
                  size={20}
                  color={tint}
                  accessibilityElementsHidden
                  importantForAccessibility="no-hide-descendants"
                />
              ) : null}
              {showBadge && (
                <View
                  // Brand-gold dot anchored top-right of the icon, with the
                  // count rendered inside in navy. Hidden from a11y because
                  // the count is communicated via the parent Pressable's label.
                  accessibilityElementsHidden={true}
                  importantForAccessibility="no-hide-descendants"
                  className="absolute -top-1 -right-2.5 min-w-[16px] h-[16px] rounded-full bg-gold items-center justify-center px-1"
                >
                  <Text className="text-navy text-body-xs font-display-bold">
                    {badgeCount > 99 ? '99+' : badgeCount}
                  </Text>
                </View>
              )}
            </View>
            <Text
              className={`font-display-bold text-body-xs mt-0.5 ${
                focused ? 'text-navy' : 'text-muted'
              }`}
            >
              {label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export default function TabsLayout() {
  const { data: unreadIntros } = useUnreadIntros();
  const { data: unreadConvs } = useUnreadCounts();

  const badges = useMemo<TabBadgeMap>(() => {
    const chats = Array.isArray(unreadConvs)
      ? unreadConvs.reduce<number>((acc, row) => acc + (row.unread_count ?? 0), 0)
      : 0;
    return {
      home: undefined,
      inbox: unreadIntros ?? 0,
      network: undefined,
      opportunities: undefined,
      chats,
    };
  }, [unreadIntros, unreadConvs]);

  return (
    <Tabs
      tabBar={(props) => <CustomTabBar {...props} badges={badges} />}
      screenOptions={{ headerShown: false }}
    >
      <Tabs.Screen name="home" />
      <Tabs.Screen name="inbox" />
      <Tabs.Screen name="network" />
      <Tabs.Screen name="opportunities" />
      <Tabs.Screen name="chats" />
    </Tabs>
  );
}
