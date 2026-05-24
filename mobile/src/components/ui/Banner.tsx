import { View, Text, Pressable } from 'react-native';
import { X } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { intentClasses, type Intent } from '~/components/ui/variants';
import { colors } from '~/theme/colors';

type Variant = 'warning' | 'info' | 'success' | 'muted';

type Props = {
  variant: Variant;
  title?: string;
  children: ReactNode;
  leadingIcon?: ReactNode;
  /** When provided, renders a top-right X button that calls this on press. */
  onDismiss?: () => void;
  testID?: string;
};

// Banner kept its own `muted` alias for backward compat; map it to the shared `neutral` intent.
const VARIANT_TO_INTENT: Record<Variant, Intent> = {
  warning: 'warning',
  info: 'info',
  success: 'success',
  muted: 'neutral',
};

export function Banner({ variant, title, children, leadingIcon, onDismiss, testID }: Props) {
  const s = intentClasses(VARIANT_TO_INTENT[variant]);
  return (
    <View
      testID={testID}
      className={`rounded-[10px] px-3 py-2.5 flex-row gap-2 ${s.bg} ${s.border}`}
    >
      {leadingIcon ? <View className="mt-0.5">{leadingIcon}</View> : null}
      <View className="flex-1">
        {title ? (
          <Text className={`font-display-bold text-body-sm ${s.text}`}>{title}</Text>
        ) : null}
        <View className={`${title ? 'mt-0.5' : ''}`}>
          {typeof children === 'string' ? (
            <Text className={`font-body text-body-sm leading-snug ${s.text}`}>{children}</Text>
          ) : (
            children
          )}
        </View>
      </View>
      {onDismiss ? (
        <Pressable
          onPress={onDismiss}
          accessibilityRole="button"
          accessibilityLabel="Dismiss"
          hitSlop={8}
          className="ml-1 -mr-1"
        >
          <X size={14} color={colors.muted} />
        </Pressable>
      ) : null}
    </View>
  );
}
