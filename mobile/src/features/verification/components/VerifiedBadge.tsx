import { View, Text } from 'react-native';

type Props = { username: string | null };

export function VerifiedBadge({ username }: Props) {
  if (!username) return null;
  return (
    <View
      testID="verified-badge"
      className="flex-row items-center self-start bg-success-bg rounded-full px-2 py-0.5"
    >
      <Text className="font-display-bold text-[9px] text-success-text">✓ @{username}</Text>
    </View>
  );
}
