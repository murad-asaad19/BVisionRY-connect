import { useState } from 'react';
import { Pressable, View, ActivityIndicator } from 'react-native';
import { Image } from 'expo-image';
import { useSignedUrl } from '~/features/media/hooks/useSignedUrl';
import { ImageViewerModal } from '~/features/media/components/ImageViewerModal';

type Props = { mediaPath: string; isMine: boolean };

export function ImageMessageBubble({ mediaPath, isMine }: Props) {
  // Supabase signed URLs expire (default ~1h). If the cached URL goes stale
  // before the user scrolls back to this bubble, expo-image's `onError` lets
  // us trigger a refetch — mirrors the playback-error refetch pattern in
  // VoiceMessageBubble.
  const { data: url, refetch } = useSignedUrl(mediaPath);
  const [open, setOpen] = useState(false);

  return (
    <>
      <Pressable
        testID={isMine ? 'image-bubble-mine' : 'image-bubble-theirs'}
        onPress={() => setOpen(true)}
        accessibilityRole="imagebutton"
        accessibilityLabel="Open image"
        className={`max-w-[70%] my-1 ${isMine ? 'self-end' : 'self-start'}`}
      >
        <View className="rounded-2xl overflow-hidden bg-white">
          {url ? (
            <Image
              source={{ uri: url }}
              style={{ width: 256, height: 256 }}
              contentFit="cover"
              transition={120}
              onError={() => {
                void refetch();
              }}
            />
          ) : (
            <View className="w-64 h-64 items-center justify-center">
              <ActivityIndicator />
            </View>
          )}
        </View>
      </Pressable>
      <ImageViewerModal visible={open} url={url ?? null} onClose={() => setOpen(false)} />
    </>
  );
}
