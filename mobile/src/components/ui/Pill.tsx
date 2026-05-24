import { View, Text } from 'react-native';
import type { ReactNode } from 'react';
import { intentClasses, type Intent } from '~/components/ui/variants';

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
  accessibilityLabel?: string;
};

// Brand-tone variants stay hard-coded; semantic ones delegate to the shared intent palette.
const BRAND_STYLES: Partial<Record<PillVariant, { bg: string; text: string; border: string }>> = {
  default: { bg: 'bg-gold-pale', text: 'text-navy', border: '' },
  solid: { bg: 'bg-gold', text: 'text-navy', border: '' },
  navy: { bg: 'bg-navy', text: 'text-white', border: '' },
  outline: { bg: 'bg-transparent', text: 'text-navy', border: 'border border-navy' },
};

const SEMANTIC_VARIANT_TO_INTENT: Partial<Record<PillVariant, Intent>> = {
  success: 'success',
  warning: 'warning',
  danger: 'danger',
  muted: 'neutral',
};

function classesFor(variant: PillVariant): { bg: string; text: string; border: string } {
  const intent = SEMANTIC_VARIANT_TO_INTENT[variant];
  if (intent) {
    // Pills opt out of intent borders (semantic ones look chip-like without an outline).
    const { bg, text } = intentClasses(intent);
    return { bg, text, border: '' };
  }
  return BRAND_STYLES[variant] ?? BRAND_STYLES.default!;
}

export function Pill({ variant = 'default', icon, children, testID, accessibilityLabel }: Props) {
  const s = classesFor(variant);
  const label = accessibilityLabel ?? (typeof children === 'string' ? children : undefined);
  return (
    <View
      testID={testID}
      accessible={Boolean(label)}
      accessibilityLabel={label}
      className={`flex-row items-center self-start rounded-full px-2 py-0.5 ${s.bg} ${s.border}`}
    >
      {icon ? <View className="mr-1">{icon}</View> : null}
      <Text className={`font-display-bold text-[10px] leading-none ${s.text}`}>{children}</Text>
    </View>
  );
}
