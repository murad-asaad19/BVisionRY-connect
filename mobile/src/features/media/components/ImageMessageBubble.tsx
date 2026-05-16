import { useState, useEffect } from 'react';
import { Pressable, Image, View, ActivityIndicator } from 'react-native';
import { getChatMediaSignedUrl } from '~/features/media/services/storage.service';
import { ImageViewerModal } from '~/features/media/components/ImageViewerModal';

type Props = { mediaPath: string; isMine: boolean };

export function ImageMessageBubble({ mediaPath, isMine }: Props) {
  const [url, setUrl] = useState<string | null>(null);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    let cancelled = false;
    getChatMediaSignedUrl(mediaPath)
      .then((u) => {
        if (!cancelled) setUrl(u);
      })
      .catch(() => {
        // signed URL failed; remain in skeleton state
      });
    return () => {
      cancelled = true;
    };
  }, [mediaPath]);

  return (
    <>
      <Pressable
        testID={isMine ? 'image-bubble-mine' : 'image-bubble-theirs'}
        onPress={() => setOpen(true)}
        className={`max-w-[70%] my-1 ${isMine ? 'self-end' : 'self-start'}`}
      >
        <View className="rounded-2xl overflow-hidden bg-white">
          {url ? (
            <Image source={{ uri: url }} className="w-64 h-64" resizeMode="cover" />
          ) : (
            <View className="w-64 h-64 items-center justify-center">
              <ActivityIndicator />
            </View>
          )}
        </View>
      </Pressable>
      <ImageViewerModal visible={open} url={url} onClose={() => setOpen(false)} />
    </>
  );
}
