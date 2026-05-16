import { View, Text } from 'react-native';
import type { ReactNode } from 'react';

export type PillVariant =
  | 'default'
  | 'solid'
  | 'navy'
  | 'outline'
  | 'success'
  | 'warning'
  | 'danger'
  | 'muted';

type Props = {
  variant?: PillVariant;
  icon?: ReactNode;
  children: ReactNode;
  testID?: string;
};

const STYLES: Record<PillVariant, { bg: string; text: string; border: string }> = {
  default: { bg: 'bg-gold-pale', text: 'text-navy', border: '' },
  solid: { bg: 'bg-gold', text: 'text-navy', border: '' },
  navy: { bg: 'bg-navy', text: 'text-white', border: '' },
  outline: { bg: 'bg-transparent', text: 'text-navy', border: 'border border-navy' },
  success: { bg: 'bg-success-bg', text: 'text-success-text', border: '' },
  warning: { bg: 'bg-warning-bg', text: 'text-warning-text', border: '' },
  danger: { bg: 'bg-danger-bg', text: 'text-danger-text', border: '' },
  muted: { bg: 'bg-slate-100', text: 'text-muted', border: '' },
};

export function Pill({ variant = 'default', icon, children, testID }: Props) {
  const s = STYLES[variant];
  return (
    <View
      testID={testID}
      className={`flex-row items-center self-start rounded-full px-2 py-0.5 ${s.bg} ${s.border}`}
    >
      {icon ? <View className="mr-1">{icon}</View> : null}
      <Text className={`font-display-bold text-[10px] leading-none ${s.text}`}>{children}</Text>
    </View>
  );
}
