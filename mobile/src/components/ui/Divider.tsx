import { View, Text } from 'react-native';

type Props = {
  /** Optional centered label (e.g. "OR" between auth options). */
  label?: string;
  orientation?: 'horizontal' | 'vertical';
  className?: string;
};

/**
 * Hairline separator. Horizontal by default; renders an inline label by
 * splitting the line into two flex segments with the text in the middle.
 * Vertical mode is a 1px column that stretches to its parent's cross-axis.
 */
export function Divider({ label, orientation = 'horizontal', className }: Props) {
  if (orientation === 'vertical') {
    return <View className={`w-px bg-border self-stretch ${className ?? ''}`} />;
  }

  if (label) {
    return (
      <View className={`flex-row items-center ${className ?? ''}`}>
        <View className="flex-1 h-px bg-border" />
        <Text className="font-body text-body-sm text-muted uppercase tracking-wide mx-3">
          {label}
        </Text>
        <View className="flex-1 h-px bg-border" />
      </View>
    );
  }

  return <View className={`h-px bg-border w-full ${className ?? ''}`} />;
}
