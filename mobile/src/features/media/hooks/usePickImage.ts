import { Alert, Linking, Platform } from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import * as ImageManipulator from 'expo-image-manipulator';
import { MAX_IMAGE_BYTES } from '~/features/media/services/media.constants';
import { i18n } from '~/lib/i18n';

export type PickedImage = {
  uri: string;
  width: number;
  height: number;
  blob: Blob;
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
  const blob = await fetch(manipulated.uri).then((r) => r.blob());

  if (blob.size > MAX_IMAGE_BYTES) {
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
    blob,
    ext: 'jpg',
  };
}
