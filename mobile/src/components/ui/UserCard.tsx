import { View, Text } from 'react-native';
import { BadgeCheck } from 'lucide-react-native';
import { Card } from '~/components/ui/Card';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { Pill } from '~/components/ui/Pill';
import { OfficeHoursBadge } from '~/features/office-hours/components/OfficeHoursBadge';
import { colors } from '~/theme/colors';

type Props = {
  variant?: 'default' | 'featured';
  name: string;
  handle: string;
  primaryRole: string;
  photoUrl: string | null;
  headline?: string | null;
  reason?: string | null;
  /** Optional "City, Country" subline rendered below the headline. */
  location?: string | null;
  /** Optional activity slot (e.g. "★ Active this week"). */
  activity?: string | null;
  verified?: boolean;
  /**
   * When true, render the `OfficeHoursBadge` alongside the name. Callers
   * pass this from data they already have — `UserCard` never queries
   * for it (per-card fetches would 404-storm a feed).
   */
  hasOfficeHours?: boolean;
  onPress?: () => void;
  testID?: string;
};

export function UserCard({
  variant = 'default',
  name,
  handle,
  primaryRole,
  photoUrl,
  headline,
  reason,
  location,
  activity,
  verified,
  hasOfficeHours,
  onPress,
  testID,
}: Props) {
  return (
    <Card variant={variant} onPress={onPress} testID={testID}>
      <View className="flex-row items-start gap-2.5">
        <AvatarCircle name={name} photoUrl={photoUrl} size={38} featured={variant === 'featured'} />
        <View className="flex-1 min-w-0">
          <View className="flex-row items-center gap-1.5 flex-wrap">
            <Text className="font-display-bold text-display-sm text-navy" numberOfLines={1}>
              {name}
            </Text>
            {verified ? (
              <View testID="user-card-verified" accessibilityLabel="Verified">
                <BadgeCheck size={14} color={colors.gold} />
              </View>
            ) : null}
            {hasOfficeHours ? <OfficeHoursBadge /> : null}
          </View>
          <Text className="font-body text-body-sm text-muted mt-0.5" numberOfLines={1}>
            @{handle} · {primaryRole}
          </Text>
          {headline ? (
            <Text className="font-body text-body-sm text-body mt-1" numberOfLines={2}>
              {headline}
            </Text>
          ) : null}
          {location ? (
            <Text className="font-body text-body-sm text-muted mt-1" numberOfLines={1}>
              {location}
            </Text>
          ) : null}
          <View className="flex-row gap-1.5 mt-1.5 flex-wrap">
            {reason ? (
              <Pill variant={variant === 'featured' ? 'solid' : 'default'}>{reason}</Pill>
            ) : null}
            {activity ? <Pill variant="success">{activity}</Pill> : null}
          </View>
        </View>
      </View>
    </Card>
  );
}
