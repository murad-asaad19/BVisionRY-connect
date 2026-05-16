import { View, Text, TextInput, type TextInputProps } from 'react-native';

type Props = {
  label?: string;
  value: string;
  onChangeText: (s: string) => void;
  placeholder?: string;
  multiline?: boolean;
  numberOfLines?: number;
  maxLength?: number;
  testID?: string;
  secureTextEntry?: boolean;
  autoCapitalize?: TextInputProps['autoCapitalize'];
  keyboardType?: TextInputProps['keyboardType'];
  autoComplete?: TextInputProps['autoComplete'];
};

export function Input({
  label,
  value,
  onChangeText,
  placeholder,
  multiline,
  numberOfLines,
  maxLength,
  testID,
  secureTextEntry,
  autoCapitalize,
  keyboardType,
  autoComplete,
}: Props) {
  return (
    <View className="mb-2">
      {label ? (
        <Text className="font-display-semibold text-[10px] text-muted uppercase tracking-wide mb-1">
          {label}
        </Text>
      ) : null}
      <TextInput
        testID={testID}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor="#94a3b8"
        multiline={multiline}
        numberOfLines={numberOfLines}
        maxLength={maxLength}
        secureTextEntry={secureTextEntry}
        autoCapitalize={autoCapitalize}
        keyboardType={keyboardType}
        autoComplete={autoComplete}
        className={`bg-white border-[1.5px] border-border rounded-[10px] px-3 py-2 text-[12px] text-body font-body ${multiline ? 'min-h-24' : ''}`}
        style={multiline ? { textAlignVertical: 'top' } : undefined}
      />
    </View>
  );
}
