import { View, Text } from 'react-native';
import type { LucideIcon } from 'lucide-react-native';
import { Button, type ButtonVariant } from '~/components/ui/Button';
import { colors } from '~/theme/colors';

type EmptyAction = {
  label: string;
  onPress: () => void;
  /** Defaults to `primary`. Only `primary` and `gold` are exposed on purpose
   *  — empty states never need destructive or outline CTAs. */
  variant?: Extract<ButtonVariant, 'primary' | 'gold'>;
};

type Props = {
  icon: LucideIcon;
  title: string;
  body?: string;
  action?: EmptyAction;
  testID?: string;
};

/**
 * Branded empty state. Visual mirrors the existing `EmptyInbox` treatment:
 * gold-pale halo around a lucide icon, navy title, muted body, optional CTA.
 * Replaces the five bespoke empty-list implementations the audit calls out
 * in P1-5.
 */
export function EmptyState({ icon: Icon, title, body, action, testID }: Props) {
  return (
    <View testID={testID} className="py-12 px-6 items-center">
      <View className="w-16 h-16 rounded-full bg-gold-pale items-center justify-center">
        <Icon size={28} color={colors.gold} />
      </View>
      <Text className="font-display-bold text-display-md text-navy text-center mt-4">{title}</Text>
      {body ? (
        <Text className="font-body text-body-md text-muted text-center mt-1.5">{body}</Text>
      ) : null}
      {action ? (
        <View className="w-full mt-4">
          <Button variant={action.variant ?? 'primary'} onPress={action.onPress}>
            {action.label}
          </Button>
        </View>
      ) : null}
    </View>
  );
}
