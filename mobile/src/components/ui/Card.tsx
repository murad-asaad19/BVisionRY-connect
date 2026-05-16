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
  const className = `rounded-[14px] p-3 ${base}`;
  if (onPress) {
    return (
      <Pressable testID={testID} onPress={onPress} className={className}>
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
