import { View, Text, Pressable } from 'react-native';
import type { ReactNode } from 'react';

type Props = {
  label: string;
  description?: string;
  onPress?: () => void;
  rightSlot?: ReactNode;
  isFirst?: boolean;
  isLast?: boolean;
  testID?: string;
};

export function SettingsRow({
  label,
  description,
  onPress,
  rightSlot,
  isFirst,
  isLast,
  testID,
}: Props) {
  const radius =
    isFirst && isLast
      ? 'rounded-[10px]'
      : isFirst
        ? 'rounded-t-[10px]'
        : isLast
          ? 'rounded-b-[10px]'
          : '';
  const border = isLast ? '' : 'border-b border-slate-100';
  const Comp = onPress ? Pressable : View;
  return (
    <Comp
      testID={testID}
      onPress={onPress}
      accessibilityRole={onPress ? 'button' : undefined}
      accessibilityLabel={onPress ? label : undefined}
      className={`bg-white px-3.5 py-3 flex-row items-center justify-between ${radius} ${border}`}
    >
      <View className="flex-1 mr-2">
        <Text className="font-display-semibold text-[12px] text-body">{label}</Text>
        {description ? (
          <Text className="font-body text-[10px] text-muted mt-0.5 leading-snug">
            {description}
          </Text>
        ) : null}
      </View>
      {rightSlot ?? (onPress ? <Text className="text-muted text-[14px]">›</Text> : null)}
    </Comp>
  );
}
