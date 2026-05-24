import * as React from 'react';
import { Pressable, Text, ActivityIndicator, View } from 'react-native';
import type { ReactNode } from 'react';
import { colors } from '~/theme/colors';

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

// Spinner stroke must match the variant's text color to stay legible against
// the background. Keyed by the *effective* variant (disabled/loading override),
// not the raw prop, so the spinner color tracks the actual background.
const VARIANT_SPINNER: Record<ButtonVariant, string> = {
  primary: colors.white,
  gold: colors.navy,
  outline: colors.navy,
  'outline-danger': colors.danger,
  danger: colors.white,
  disabled: colors.white,
  apple: colors.white,
};

const SIZE_PAD: Record<ButtonSize, string> = {
  default: 'px-4 py-2.5',
  small: 'px-3 py-1.5',
};

const SIZE_TEXT: Record<ButtonSize, string> = {
  default: 'text-[13px]',
  small: 'text-[11px]',
};

export const Button = React.forwardRef<View, Props>(function Button(
  {
    variant = 'primary',
    size = 'default',
    fullWidth = true,
    onPress,
    disabled = false,
    loading = false,
    children,
    testID,
    accessibilityLabel,
  },
  ref
) {
  const effectiveVariant: ButtonVariant = disabled || loading ? 'disabled' : variant;
  // Expand touch target for the smaller size to meet the 44px guideline without growing the visual chip.
  const hitSlop = size === 'small' ? { top: 8, bottom: 8, left: 8, right: 8 } : undefined;
  return (
    <Pressable
      ref={ref}
      testID={testID}
      onPress={onPress}
      disabled={disabled || loading}
      hitSlop={hitSlop}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      accessibilityState={{ disabled: disabled || loading, busy: loading }}
      className={`rounded-[10px] items-center justify-center ${SIZE_PAD[size]} ${VARIANT_BG[effectiveVariant]} ${VARIANT_BORDER[effectiveVariant]} ${fullWidth ? 'w-full' : 'self-start'}`}
    >
      {loading ? (
        <ActivityIndicator color={VARIANT_SPINNER[effectiveVariant]} />
      ) : typeof children === 'string' ? (
        <Text className={`font-display-bold ${SIZE_TEXT[size]} ${VARIANT_TEXT[effectiveVariant]}`}>
          {children}
        </Text>
      ) : (
        <View className="flex-row items-center">{children}</View>
      )}
    </Pressable>
  );
});
