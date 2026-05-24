import { Pressable, View } from 'react-native';
import type { LucideIcon } from 'lucide-react-native';
import { colors } from '~/theme/colors';

export type IconButtonSize = 'sm' | 'md' | 'lg';
export type IconButtonVariant = 'plain' | 'subtle' | 'navy';

type Props = {
  icon: LucideIcon;
  onPress?: () => void;
  /** Required for accessibility — screen-readers announce this. */
  label: string;
  size?: IconButtonSize;
  variant?: IconButtonVariant;
  disabled?: boolean;
  testID?: string;
};

// Visual chip size in pts. Sub-44pt sizes rely on `hitSlop` to reach the
// 44pt touch-target floor (Apple HIG / WCAG 2.5.5).
const SIZE_DIM: Record<IconButtonSize, number> = { sm: 32, md: 40, lg: 44 };
const ICON_SIZE: Record<IconButtonSize, number> = { sm: 16, md: 20, lg: 22 };

function hitSlopFor(size: IconButtonSize) {
  const dim = SIZE_DIM[size];
  if (dim >= 44) return undefined;
  const pad = (44 - dim) / 2;
  return { top: pad, bottom: pad, left: pad, right: pad };
}

const VARIANT_BG: Record<IconButtonVariant, string> = {
  plain: 'bg-transparent',
  subtle: 'bg-slate-100',
  navy: 'bg-navy',
};

const VARIANT_ICON_COLOR: Record<IconButtonVariant, string> = {
  plain: colors.navy,
  subtle: colors.navy,
  navy: colors.white,
};

export function IconButton({
  icon: Icon,
  onPress,
  label,
  size = 'md',
  variant = 'plain',
  disabled = false,
  testID,
}: Props) {
  const dim = SIZE_DIM[size];
  const iconColor = disabled ? colors.muted : VARIANT_ICON_COLOR[variant];
  return (
    <Pressable
      testID={testID}
      onPress={onPress}
      disabled={disabled}
      hitSlop={hitSlopFor(size)}
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled }}
      className={`rounded-full items-center justify-center active:opacity-70 ${VARIANT_BG[variant]} ${disabled ? 'opacity-50' : ''}`}
      style={{ width: dim, height: dim }}
    >
      <View pointerEvents="none">
        <Icon size={ICON_SIZE[size]} color={iconColor} />
      </View>
    </Pressable>
  );
}
