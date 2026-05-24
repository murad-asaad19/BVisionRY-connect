import { useState } from 'react';
import { View, Text, Image } from 'react-native';
import { colors } from '~/theme/colors';

export type AvatarSize = 32 | 38 | 48 | 64 | 76 | 96;

type Props = {
  name: string;
  photoUrl?: string | null;
  size?: AvatarSize;
  featured?: boolean;
  testID?: string;
};

const TEXT_SIZE: Record<AvatarSize, number> = {
  32: 13,
  38: 15,
  48: 19,
  64: 25,
  76: 30,
  96: 38,
};

function initials(name: string): string {
  const trimmed = (name ?? '').trim();
  if (!trimmed) return '?';
  const parts = trimmed.split(/\s+/);
  const first = parts[0]?.[0] ?? '';
  const last = parts.length > 1 ? (parts[parts.length - 1]?.[0] ?? '') : '';
  return (first + last).toUpperCase() || '?';
}

export function AvatarCircle({ name, photoUrl, size = 48, featured = false, testID }: Props) {
  const [imageFailed, setImageFailed] = useState(false);
  const dim = { width: size, height: size, borderRadius: size / 2 };
  // Double-ring halo: inner white ring (2px), outer gold ring (1px).
  // RN doesn't render multi-shadow box-shadow consistently — use a wrapping View with padding + a colored bg.
  const haloOuter = featured ? colors.gold : colors.goldPale;
  const showImage = photoUrl && !imageFailed;
  return (
    <View
      testID={testID ?? 'avatar-circle'}
      accessibilityRole="image"
      accessibilityLabel={name}
      style={{
        padding: 1,
        backgroundColor: haloOuter,
        borderRadius: (size + 6) / 2,
        width: size + 6,
        height: size + 6,
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <View
        style={{
          padding: 2,
          backgroundColor: colors.white,
          borderRadius: (size + 4) / 2,
          width: size + 4,
          height: size + 4,
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {showImage ? (
          <Image
            source={{ uri: photoUrl! }}
            style={dim}
            accessibilityIgnoresInvertColors
            onError={() => setImageFailed(true)}
          />
        ) : (
          <View
            style={{
              ...dim,
              backgroundColor: colors.navy,
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Text
              style={{
                color: colors.white,
                fontSize: TEXT_SIZE[size],
                fontFamily: 'Dosis_700Bold',
              }}
            >
              {initials(name)}
            </Text>
          </View>
        )}
      </View>
    </View>
  );
}
