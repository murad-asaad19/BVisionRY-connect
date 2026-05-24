import { View, Text } from 'react-native';
import type { ReactNode } from 'react';
import { intentClasses, type Intent } from '~/components/ui/variants';

type Variant = 'warning' | 'info' | 'success' | 'muted';

type Props = {
  variant: Variant;
  title?: string;
  children: ReactNode;
  leadingIcon?: ReactNode;
  testID?: string;
};

// Banner kept its own `muted` alias for backward compat; map it to the shared `neutral` intent.
const VARIANT_TO_INTENT: Record<Variant, Intent> = {
  warning: 'warning',
  info: 'info',
  success: 'success',
  muted: 'neutral',
};

export function Banner({ variant, title, children, leadingIcon, testID }: Props) {
  const s = intentClasses(VARIANT_TO_INTENT[variant]);
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
