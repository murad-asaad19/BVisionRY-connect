import { Pressable, Text, View } from 'react-native';
import type { LucideIcon } from 'lucide-react-native';
import { colors } from '~/theme/colors';

type Props = {
  active: boolean;
  onPress: () => void;
  label: string;
  icon?: LucideIcon;
  count?: number;
  testID?: string;
};

export function FilterChip({ active, onPress, label, icon: Icon, count, testID }: Props) {
  const containerCls = active
    ? 'bg-navy border border-navy'
    : 'bg-white border border-border';
  const textCls = active ? 'text-white' : 'text-body';
  const iconColor = active ? colors.white : colors.navy;
  return (
    <Pressable
      testID={testID}
      onPress={onPress}
      accessibilityRole="button"
      accessibilityState={{ selected: active }}
      accessibilityLabel={label}
      hitSlop={{ top: 6, bottom: 6, left: 4, right: 4 }}
      className={`flex-row items-center self-start rounded-full px-3 py-1.5 active:opacity-80 ${containerCls}`}
    >
      {Icon ? (
        <View className="mr-1.5">
          <Icon size={14} color={iconColor} />
        </View>
      ) : null}
      <Text className={`font-display-semibold text-display-xs ${textCls}`}>
        {label}
        {typeof count === 'number' ? ` (${count})` : ''}
      </Text>
    </Pressable>
  );
}
