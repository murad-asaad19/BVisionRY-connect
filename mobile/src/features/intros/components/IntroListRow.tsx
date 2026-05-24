import { View, Text, Pressable } from 'react-native';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { IntroStateBadge, type IntroBadgeAudience } from './IntroStateBadge';
import type { IntroRow } from '~/features/intros/services/intros.service';
import type { Database } from '~/lib/supabase/types.gen';

type ProfileLite = Pick<
  Database['public']['Tables']['profiles']['Row'],
  'name' | 'handle' | 'photo_url'
>;

type Props = {
  intro: IntroRow;
  counterpart: ProfileLite | null;
  onPress: () => void;
  /** Audience viewing the row. Sender's row never shows "Declined" per §12. */
  audience?: IntroBadgeAudience;
};

export function IntroListRow({ intro, counterpart, onPress, audience = 'recipient' }: Props) {
  return (
    <Pressable
      testID={`intro-row-${intro.id}`}
      onPress={onPress}
      className="flex-row items-start bg-white border border-border rounded-xl px-card-lg py-3 mx-gutter mb-3 active:opacity-80"
    >
      <AvatarCircle
        name={counterpart?.name ?? '?'}
        photoUrl={counterpart?.photo_url ?? null}
        size={48}
      />
      <View className="ml-4 flex-1">
        <View className="flex-row items-center justify-between mb-1">
          <Text className="font-display-bold text-display-sm text-navy flex-1 mr-2" numberOfLines={1}>
            {counterpart?.name ?? 'Unknown'}
          </Text>
          <IntroStateBadge
            state={intro.state}
            audience={audience}
            expiresAt={intro.expires_at}
          />
        </View>
        <Text className="font-body text-body-sm text-muted" numberOfLines={1}>
          @{counterpart?.handle ?? '?'}
        </Text>
        {/* Two-line note preview — let RN do the ellipsis instead of slicing
            characters (which mishandles multi-byte/emoji and trims at code units). */}
        <Text
          className="font-body text-body-md text-muted mt-1"
          numberOfLines={2}
          ellipsizeMode="tail"
        >
          {intro.note}
        </Text>
      </View>
    </Pressable>
  );
}
