import { View, Text } from 'react-native';
import type { ReactNode } from 'react';

type Variant = 'warning' | 'info' | 'success' | 'muted';

type Props = {
  variant: Variant;
  title?: string;
  children: ReactNode;
  leadingIcon?: ReactNode;
  testID?: string;
};

const STYLES: Record<Variant, { bg: string; text: string; border: string }> = {
  warning: {
    bg: 'bg-warning-bg',
    text: 'text-warning-text',
    border: 'border border-warning-border',
  },
  info: {
    bg: 'bg-info-bg',
    text: 'text-info-text',
    border: 'border border-info-border',
  },
  success: {
    bg: 'bg-success-bg',
    text: 'text-success-text',
    border: 'border border-success-border',
  },
  muted: {
    bg: 'bg-slate-100',
    text: 'text-body',
    border: 'border border-border',
  },
};

export function Banner({ variant, title, children, leadingIcon, testID }: Props) {
  const s = STYLES[variant];
  return (
    <View
      testID={testID}
      className={`rounded-[10px] px-3 py-2.5 flex-row gap-2 ${s.bg} ${s.border}`}
    >
      {leadingIcon ? <View className="mt-0.5">{leadingIcon}</View> : null}
      <View className="flex-1">
        {title ? <Text className={`font-display-bold text-[11px] ${s.text}`}>{title}</Text> : null}
        <View className={`${title ? 'mt-0.5' : ''}`}>
          {typeof children === 'string' ? (
            <Text className={`font-body text-[11px] leading-snug ${s.text}`}>{children}</Text>
          ) : (
            children
          )}
        </View>
      </View>
    </View>
  );
}
