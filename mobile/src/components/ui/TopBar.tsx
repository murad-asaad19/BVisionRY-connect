import { View, Text, Pressable } from 'react-native';
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
};

export function TopBar({ title, titleTestID, actions, leading }: Props) {
  return (
    <View className="bg-white px-4 pt-3.5 pb-2.5 border-b border-border flex-row items-center justify-between">
      <View className="flex-row items-center gap-2">
        {leading}
        <Text testID={titleTestID} className="font-display-bold text-[16px] text-navy">
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
