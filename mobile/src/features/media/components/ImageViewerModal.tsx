import { Modal, Pressable, Image } from 'react-native';

type Props = { visible: boolean; url: string | null; onClose: () => void };

export function ImageViewerModal({ visible, url, onClose }: Props) {
  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <Pressable
        testID="image-viewer-backdrop"
        onPress={onClose}
        accessibilityRole="button"
        accessibilityLabel="Close image viewer"
        className="flex-1 bg-black/95 items-center justify-center"
      >
        {url && <Image source={{ uri: url }} className="w-full h-3/4" resizeMode="contain" />}
      </Pressable>
    </Modal>
  );
}
