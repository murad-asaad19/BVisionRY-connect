import { Pressable, Text, ActivityIndicator, View } from 'react-native';
import type { ReactNode } from 'react';

export type ButtonVariant =
  | 'primary'
  | 'gold'
  | 'outline'
  | 'outline-danger'
  | 'danger'
  | 'disabled'
  | 'apple';
export type ButtonSize = 'default' | 'small';

type Props = {
  variant?: ButtonVariant;
  size?: ButtonSize;
  fullWidth?: boolean;
  onPress?: () => void;
  disabled?: boolean;
  loading?: boolean;
  children: ReactNode;
  testID?: string;
  accessibilityLabel?: string;
};

const VARIANT_BG: Record<ButtonVariant, string> = {
  primary: 'bg-navy',
  gold: 'bg-gold',
  outline: 'bg-white',
  'outline-danger': 'bg-white',
  danger: 'bg-danger-text',
  disabled: 'bg-slate-300',
  apple: 'bg-black',
};

const VARIANT_TEXT: Record<ButtonVariant, string> = {
  primary: 'text-white',
  gold: 'text-navy',
  outline: 'text-navy',
  'outline-danger': 'text-danger-text',
  danger: 'text-white',
  disabled: 'text-white',
  apple: 'text-white',
};

const VARIANT_BORDER: Record<ButtonVariant, string> = {
  primary: '',
  gold: '',
  outline: 'border-[1.5px] border-navy',
  'outline-danger': 'border-[1.5px] border-danger-text',
  danger: 'border border-danger-text',
  disabled: '',
  apple: '',
};

const SIZE_PAD: Record<ButtonSize, string> = {
  default: 'px-4 py-2.5',
  small: 'px-3 py-1.5',
};

const SIZE_TEXT: Record<ButtonSize, string> = {
  default: 'text-[13px]',
  small: 'text-[11px]',
};

export function Button({
  variant = 'primary',
  size = 'default',
  fullWidth = true,
  onPress,
  disabled = false,
  loading = false,
  children,
  testID,
  accessibilityLabel,
}: Props) {
  const effectiveVariant: ButtonVariant = disabled || loading ? 'disabled' : variant;
  return (
    <Pressable
      testID={testID}
      onPress={onPress}
      disabled={disabled || loading}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      className={`rounded-[10px] items-center justify-center ${SIZE_PAD[size]} ${VARIANT_BG[effectiveVariant]} ${VARIANT_BORDER[effectiveVariant]} ${fullWidth ? 'w-full' : 'self-start'}`}
    >
      {loading ? (
        <ActivityIndicator color="#ffffff" />
      ) : typeof children === 'string' ? (
        <Text className={`font-display-bold ${SIZE_TEXT[size]} ${VARIANT_TEXT[effectiveVariant]}`}>
          {children}
        </Text>
      ) : (
        <View className="flex-row items-center">{children}</View>
      )}
    </Pressable>
  );
}
