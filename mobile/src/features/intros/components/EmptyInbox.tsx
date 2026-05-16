import { View, Text } from 'react-native';
import { router } from 'expo-router';
import { Button } from '~/components/ui/Button';

type Props = { segment: 'received' | 'sent' };

export function EmptyInbox({ segment }: Props) {
  return (
    <View testID="empty-inbox" className="py-12 px-6 items-center">
      <View className="w-20 h-20 rounded-full bg-gold-pale items-center justify-center mb-4">
        <Text className="text-[28px]">✉</Text>
      </View>
      <Text className="font-display-bold text-[16px] text-navy mb-1">No intros yet</Text>
      <Text className="font-body text-[12px] text-muted text-center mb-3 leading-snug">
        {segment === 'received'
          ? 'When someone sends you an intro, it shows up here. Check back tomorrow at 4 AM your time for new picks.'
          : "You haven't sent any intros yet. Find someone interesting in Discover."}
      </Text>
      <Button
        testID="empty-inbox-browse"
        variant="primary"
        fullWidth={false}
        onPress={() => router.push('/(app)/(tabs)/home')}
      >
        Browse Today&apos;s matches
      </Button>
    </View>
  );
}
