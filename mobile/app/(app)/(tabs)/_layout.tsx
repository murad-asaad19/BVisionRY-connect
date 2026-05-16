import { Tabs } from 'expo-router';
import { View, Text, Pressable } from 'react-native';
import type { BottomTabBarProps } from '@react-navigation/bottom-tabs';

const ICONS: Record<string, string> = {
  home: '🏠',
  inbox: '📬',
  network: '🤝',
  chats: '💬',
};

const LABELS: Record<string, string> = {
  home: 'Home',
  inbox: 'Inbox',
  network: 'Network',
  chats: 'Chats',
};

function CustomTabBar({ state, navigation }: BottomTabBarProps) {
  return (
    <View className="bg-white border-t border-border flex-row justify-around py-2">
      {state.routes.map((route, i) => {
        const focused = state.index === i;
        const icon = ICONS[route.name] ?? '·';
        const label = LABELS[route.name] ?? route.name;
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
            accessibilityLabel={route.name}
            className="items-center flex-1"
          >
            <Text className={`text-[18px] ${focused ? 'text-navy' : 'text-muted'}`}>{icon}</Text>
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
  return (
    <Tabs tabBar={(props) => <CustomTabBar {...props} />} screenOptions={{ headerShown: false }}>
      <Tabs.Screen name="home" />
      <Tabs.Screen name="inbox" />
      <Tabs.Screen name="network" />
      <Tabs.Screen name="chats" />
    </Tabs>
  );
}
