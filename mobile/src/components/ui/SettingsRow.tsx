import { Children, isValidElement, cloneElement, type ReactElement } from 'react';
import { View, Text, Pressable } from 'react-native';
import { ChevronRight } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { colors } from '~/theme/colors';

type RowProps = {
  label: string;
  description?: string;
  onPress?: () => void;
  rightSlot?: ReactNode;
  /** @deprecated Use `SettingsGroup` instead — derived automatically. */
  isFirst?: boolean;
  /** @deprecated Use `SettingsGroup` instead — derived automatically. */
  isLast?: boolean;
  testID?: string;
};

/**
 * Groups SettingsRow children into a rounded card, owning corner rounding and dividers
 * so each row can stay presentation-dumb. Backward-compatible: rows still accept
 * `isFirst`/`isLast` directly when used standalone.
 */
export function SettingsGroup({ children }: { children: ReactNode }) {
  const rows = Children.toArray(children).filter(isValidElement) as ReactElement<RowProps>[];
  const last = rows.length - 1;
  return (
    <View>
      {rows.map((row, i) =>
        cloneElement(row, {
          isFirst: i === 0,
          isLast: i === last,
          key: row.key ?? i,
        })
      )}
    </View>
  );
}

export function SettingsRow({
  label,
  description,
  onPress,
  rightSlot,
  isFirst,
  isLast,
  testID,
}: RowProps) {
  const radius =
    isFirst && isLast
      ? 'rounded-[10px]'
      : isFirst
        ? 'rounded-t-[10px]'
        : isLast
          ? 'rounded-b-[10px]'
          : '';
  const border = isLast ? '' : 'border-b border-slate-100';
  const Comp = onPress ? Pressable : View;
  return (
    <Comp
      testID={testID}
      onPress={onPress}
      accessibilityRole={onPress ? 'button' : undefined}
      accessibilityLabel={onPress ? label : undefined}
      className={`bg-white px-3.5 py-3 flex-row items-center justify-between ${radius} ${border} ${onPress ? 'active:bg-slate-100' : ''}`}
    >
      <View className="flex-1 mr-2">
        <Text className="font-display-semibold text-body-md text-body">{label}</Text>
        {description ? (
          <Text className="font-body text-body-xs text-muted mt-0.5 leading-snug">
            {description}
          </Text>
        ) : null}
      </View>
      {rightSlot ?? (onPress ? <ChevronRight size={16} color={colors.muted} /> : null)}
    </Comp>
  );
}
