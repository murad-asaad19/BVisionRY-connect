import * as ImagePicker from 'expo-image-picker';
import * as ImageManipulator from 'expo-image-manipulator';

export type PickedImage = {
  uri: string;
  width: number;
  height: number;
  blob: Blob;
  ext: 'jpg';
};

export async function pickImage(opts?: { aspect?: [number, number] }): Promise<PickedImage | null> {
  const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
  if (status !== 'granted') return null;

  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ['images'],
    quality: 1,
    aspect: opts?.aspect,
    allowsEditing: !!opts?.aspect,
  });
  if (result.canceled || !result.assets?.length) return null;

  const asset = result.assets[0];
  if (!asset) return null;
  // Downscale to max 1600px on the long side, re-encode JPEG 0.8
  const manipulated = await ImageManipulator.manipulateAsync(
    asset.uri,
    [{ resize: { width: Math.min(1600, asset.width) } }],
    { compress: 0.8, format: ImageManipulator.SaveFormat.JPEG }
  );
  const blob = await fetch(manipulated.uri).then((r) => r.blob());
  return {
    uri: manipulated.uri,
    width: manipulated.width,
    height: manipulated.height,
    blob,
    ext: 'jpg',
  };
}
