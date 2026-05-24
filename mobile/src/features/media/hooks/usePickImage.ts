import { Alert, Linking, Platform } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import * as ImageManipulator from 'expo-image-manipulator';
import { File } from 'expo-file-system';
import { MAX_IMAGE_BYTES } from '~/features/media/services/media.constants';
import { i18n } from '~/lib/i18n';

export type PickedImage = {
  uri: string;
  width: number;
  height: number;
  /** Raw bytes loaded into memory — safe to upload via supabase-js on both
   *  web and native. The historic `fetch(uri).blob()` path returned a lazy
   *  Blob on React Native that uploaded as 0 bytes through XHR. */
  bytes: Uint8Array;
  size: number;
  ext: 'jpg';
};

function surfacePermissionDenied() {
  Alert.alert(
    i18n.t('media.permissionPhotoTitle'),
    i18n.t('media.permissionPhotoBody'),
    [
      { text: i18n.t('media.cancel'), style: 'cancel' },
      {
        text: i18n.t('media.openSettings'),
        onPress: () => {
          if (Platform.OS === 'web') return;
          void Linking.openSettings();
        },
      },
    ]
  );
}

export async function pickImage(opts?: { aspect?: [number, number] }): Promise<PickedImage | null> {
  const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
  if (status !== 'granted') {
    surfacePermissionDenied();
    return null;
  }

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
  const bytes = await new File(manipulated.uri).bytes();

  if (bytes.byteLength > MAX_IMAGE_BYTES) {
    Alert.alert(
      i18n.t('media.imageTooLargeTitle'),
      i18n.t('media.imageTooLargeBody', { maxMb: Math.round(MAX_IMAGE_BYTES / (1024 * 1024)) })
    );
    return null;
  }

  return {
    uri: manipulated.uri,
    width: manipulated.width,
    height: manipulated.height,
    bytes,
    size: bytes.byteLength,
    ext: 'jpg',
  };
}
