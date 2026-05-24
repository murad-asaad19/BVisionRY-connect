import { View, Text } from 'react-native';
import { Minus, Plus } from 'lucide-react-native';
import { IconButton } from '~/components/ui/IconButton';

type Props = {
  value: number;
  onChange: (v: number) => void;
  min?: number;
  max?: number;
  step?: number;
  suffix?: string;
  testID?: string;
};

export function Stepper({
  value,
  onChange,
  min = Number.NEGATIVE_INFINITY,
  max = Number.POSITIVE_INFINITY,
  step = 1,
  suffix,
  testID,
}: Props) {
  const atMin = value <= min;
  const atMax = value >= max;

  const decrement = () => {
    const next = Math.max(min, value - step);
    if (next !== value) onChange(next);
  };
  const increment = () => {
    const next = Math.min(max, value + step);
    if (next !== value) onChange(next);
  };

  return (
    <View
      testID={testID}
      accessibilityRole="adjustable"
      accessibilityValue={{ min: Number.isFinite(min) ? min : undefined, max: Number.isFinite(max) ? max : undefined, now: value }}
      className="flex-row items-center"
    >
      <IconButton
        icon={Minus}
        variant="subtle"
        size="sm"
        onPress={decrement}
        disabled={atMin}
        label="Decrease"
        testID={testID ? `${testID}-decrement` : undefined}
      />
      <Text
        testID={testID ? `${testID}-value` : undefined}
        className="font-display-bold text-display-md text-navy w-12 text-center"
      >
        {value}
        {suffix ?? ''}
      </Text>
      <IconButton
        icon={Plus}
        variant="subtle"
        size="sm"
        onPress={increment}
        disabled={atMax}
        label="Increase"
        testID={testID ? `${testID}-increment` : undefined}
      />
    </View>
  );
}
