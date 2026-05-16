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
  const previewNote = intro.note.length > 60 ? intro.note.slice(0, 57) + '…' : intro.note;
  return (
    <Pressable
      testID={`intro-row-${intro.id}`}
      onPress={onPress}
      className="flex-row items-start bg-white border border-border rounded-xl px-4 py-3 mx-6 mb-3"
    >
      <AvatarCircle
        name={counterpart?.name ?? '?'}
        photoUrl={counterpart?.photo_url ?? null}
        size={48}
      />
      <View className="ml-4 flex-1">
        <View className="flex-row items-center justify-between mb-1">
          <Text className="text-body font-semibold" numberOfLines={1}>
            {counterpart?.name ?? 'Unknown'}
          </Text>
          <IntroStateBadge state={intro.state} audience={audience} />
        </View>
        <Text className="text-muted text-xs" numberOfLines={1}>
          @{counterpart?.handle ?? '?'}
        </Text>
        <Text className="text-muted text-sm mt-1" numberOfLines={2}>
          {previewNote}
        </Text>
      </View>
    </Pressable>
  );
}
