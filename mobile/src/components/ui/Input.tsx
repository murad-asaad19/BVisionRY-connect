import * as React from 'react';
import { View, Text, TextInput, type TextInputProps } from 'react-native';
import { colors } from '~/theme/colors';

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
  autoCorrect?: TextInputProps['autoCorrect'];
  autoComplete?: TextInputProps['autoComplete'];
  keyboardType?: TextInputProps['keyboardType'];
  textContentType?: TextInputProps['textContentType'];
  returnKeyType?: TextInputProps['returnKeyType'];
  onBlur?: TextInputProps['onBlur'];
  onSubmitEditing?: TextInputProps['onSubmitEditing'];
  editable?: TextInputProps['editable'];
  /** Inline validation message rendered below the field. */
  errorText?: string;
};

export const Input = React.forwardRef<TextInput, Props>(function Input(
  {
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
    autoCorrect,
    autoComplete,
    keyboardType,
    textContentType,
    returnKeyType,
    onBlur,
    onSubmitEditing,
    editable,
    errorText,
  },
  ref
) {
  const hasError = Boolean(errorText);
  return (
    <View className="mb-2">
      {label ? (
        <Text className="font-display-semibold text-[10px] text-muted uppercase tracking-wide mb-1">
          {label}
        </Text>
      ) : null}
      <TextInput
        ref={ref}
        testID={testID}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={colors.muted}
        multiline={multiline}
        numberOfLines={numberOfLines}
        maxLength={maxLength}
        secureTextEntry={secureTextEntry}
        autoCapitalize={autoCapitalize}
        autoCorrect={autoCorrect}
        autoComplete={autoComplete}
        keyboardType={keyboardType}
        textContentType={textContentType}
        returnKeyType={returnKeyType}
        onBlur={onBlur}
        onSubmitEditing={onSubmitEditing}
        editable={editable}
        accessibilityLabel={label ?? placeholder}
        accessibilityState={hasError ? { invalid: true } : undefined}
        className={`bg-white border-[1.5px] ${hasError ? 'border-danger-border' : 'border-border'} rounded-[10px] px-3 py-2 text-[12px] text-body font-body ${multiline ? 'min-h-24' : ''}`}
        style={multiline ? { textAlignVertical: 'top' } : undefined}
      />
      {errorText ? (
        <Text
          testID={testID ? `${testID}-error` : undefined}
          accessibilityLiveRegion="polite"
          className="font-body text-[10px] text-danger-text mt-1"
        >
          {errorText}
        </Text>
      ) : null}
    </View>
  );
});
