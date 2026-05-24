import { View, Text, Pressable, Platform } from 'react-native';

export type SegmentedControlSize = 'sm' | 'md';

export type SegmentedOption = {
  value: string;
  label: string;
  testID?: string;
};

type Props = {
  options: SegmentedOption[];
  value: string;
  onChange: (v: string) => void;
  size?: SegmentedControlSize;
  testID?: string;
};

const SIZE_PAD: Record<SegmentedControlSize, string> = {
  sm: 'py-1',
  md: 'py-1.5',
};

// Elevation 1 on Android, subtle shadow elsewhere (web/iOS), so the active
// segment lifts above the slate trough.
const ACTIVE_ELEVATION =
  Platform.OS === 'android'
    ? { elevation: 1 }
    : { shadowColor: '#000', shadowOpacity: 0.08, shadowRadius: 2, shadowOffset: { width: 0, height: 1 } };

export function SegmentedControl({ options, value, onChange, size = 'md', testID }: Props) {
  return (
    <View
      testID={testID}
      accessibilityRole="tablist"
      className="flex-row bg-slate-100 rounded-lg p-0.5"
    >
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <Pressable
            key={opt.value}
            testID={opt.testID}
            onPress={() => {
              if (!active) onChange(opt.value);
            }}
            accessibilityRole="tab"
            accessibilityState={{ selected: active }}
            accessibilityLabel={opt.label}
            className={`flex-1 items-center justify-center ${SIZE_PAD[size]} ${
              active ? 'bg-white rounded-md' : ''
            }`}
            style={active ? ACTIVE_ELEVATION : undefined}
          >
            <Text
              className={`font-display-semibold text-display-sm ${
                active ? 'text-navy' : 'text-muted'
              }`}
            >
              {opt.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}
