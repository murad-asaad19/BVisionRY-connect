import { Tabs } from 'expo-router';
import { useMemo } from 'react';
import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import type { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import { useUnreadIntros } from '~/features/intros/hooks/useUnreadIntros';
import { useUnreadCounts } from '~/features/chat/hooks/useUnreadCounts';

const ICONS: Record<string, string> = {
  home: '🏠',
  inbox: '📬',
  network: '🤝',
  opportunities: '💼',
  chats: '💬',
};

type TabBadgeMap = Record<string, number | undefined>;

function CustomTabBar({
  state,
  navigation,
  badges,
}: BottomTabBarProps & { badges: TabBadgeMap }) {
  const { t } = useTranslation();
  return (
    <View className="bg-white border-t border-border flex-row justify-around py-2">
      {state.routes.map((route, i) => {
        const focused = state.index === i;
        const icon = ICONS[route.name] ?? '·';
        const label = t(`nav.tabs.${route.name}`, { defaultValue: route.name });
        const badgeCount = badges[route.name];
        const showBadge = typeof badgeCount === 'number' && badgeCount > 0;
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
          >
            <View>
              <Text
                accessibilityElementsHidden={true}
                importantForAccessibility="no-hide-descendants"
                className={`text-[18px] ${focused ? 'text-navy' : 'text-muted'}`}
              >
                {icon}
              </Text>
              {showBadge && (
                <View
                  // 16px red circle anchored top-right of the icon, with the
                  // count rendered inside. Hidden from a11y because the count
                  // is communicated via the parent Pressable's label.
                  accessibilityElementsHidden={true}
                  importantForAccessibility="no-hide-descendants"
                  className="absolute -top-1 -right-3 min-w-[16px] h-[16px] rounded-full bg-danger-border items-center justify-center px-1"
                >
                  <Text className="text-white text-[10px] font-display-bold">
                    {badgeCount > 99 ? '99+' : badgeCount}
                  </Text>
                </View>
              )}
            </View>
            <Text
              className={`font-display-bold text-[10px] mt-0.5 ${
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
