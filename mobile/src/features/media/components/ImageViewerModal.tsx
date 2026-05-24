import { Modal, Pressable, View } from 'react-native';
import { Image } from 'expo-image';

type Props = { visible: boolean; url: string | null; onClose: () => void };

/**
 * Lightweight full-screen image viewer. Backdrop press dismisses; the image
 * itself does NOT — this prevents accidental dismissal when a user wants to
 * inspect the photo (and leaves the door open for future zoom/pan gestures
 * on the image surface itself).
 *
 * TODO: pinch-to-zoom + drag-to-pan with react-native-gesture-handler +
 * reanimated. Out of scope for this pass.
 */
export function ImageViewerModal({ visible, url, onClose }: Props) {
  return (
    <Modal
      visible={visible}
      animationType="fade"
      transparent
      onRequestClose={onClose}
      accessibilityViewIsModal
    >
      <View
        testID="image-viewer-root"
        accessibilityViewIsModal
        className="flex-1 bg-black/95"
      >
        <Pressable
          testID="image-viewer-backdrop"
          onPress={onClose}
          accessibilityRole="button"
          accessibilityLabel="Close image viewer"
          className="flex-1 items-center justify-center"
        >
          {url ? (
            // The image swallows the press so backdrop-only dismissal works.
            <Pressable onPress={() => {}} accessible={false} className="w-full h-3/4">
              <Image
                source={{ uri: url }}
                style={{ width: '100%', height: '100%' }}
                contentFit="contain"
                accessibilityIgnoresInvertColors
              />
            </Pressable>
          ) : null}
        </Pressable>
      </View>
    </Modal>
  );
}
