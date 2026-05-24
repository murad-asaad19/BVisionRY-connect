import { View, Pressable } from 'react-native';
import type { ReactNode } from 'react';

type Props = {
  variant?: 'default' | 'featured';
  onPress?: () => void;
  children: ReactNode;
  testID?: string;
};

export function Card({ variant = 'default', onPress, children, testID }: Props) {
  const base =
    variant === 'featured'
      ? 'bg-gold-pale border-[1.5px] border-gold'
      : 'bg-white border border-border';
  const className = `rounded-[14px] p-card ${base}`;
  if (onPress) {
    return (
      <Pressable
        testID={testID}
        onPress={onPress}
        accessibilityRole="button"
        // Tactile press feedback — fixes the "did my tap register?" gap.
        className={`${className} active:opacity-70`}
      >
        {children}
      </Pressable>
    );
  }
  return (
    <View testID={testID} className={className}>
      {children}
    </View>
  );
}
