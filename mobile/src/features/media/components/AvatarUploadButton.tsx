import { View, Text, Pressable, Image, ActivityIndicator } from 'react-native';
import { useUploadAvatar } from '~/features/media/hooks/useUploadAvatar';
import { colors } from '~/theme/colors';

type Props = { currentPhotoUrl: string | null };

export function AvatarUploadButton({ currentPhotoUrl }: Props) {
  const upload = useUploadAvatar();
  return (
    <Pressable
      testID="avatar-upload"
      onPress={() => upload.mutate()}
      disabled={upload.isPending}
      accessibilityRole="button"
      accessibilityLabel="Upload avatar"
      className="self-center mb-4"
    >
      <View className="w-24 h-24 rounded-full bg-white border border-border items-center justify-center overflow-hidden">
        {upload.isPending ? (
          <ActivityIndicator color={colors.navy} />
        ) : currentPhotoUrl ? (
          <Image source={{ uri: currentPhotoUrl }} className="w-24 h-24" />
        ) : (
          <Text className="text-muted">Add photo</Text>
        )}
      </View>
    </Pressable>
  );
}
