import { useState } from 'react';
import { View, Text, Image } from 'react-native';

export type AvatarSize = 32 | 38 | 48 | 64 | 76 | 96;
export type AvatarTone = 'default' | 'featured' | 'muted';

type Props = {
  name: string;
  photoUrl?: string | null;
  size?: AvatarSize;
  /**
   * Visual emphasis tone. `default` gets a neutral border, `featured` a gold
   * accent ring, `muted` no border at all. Prefer over the legacy `featured`
   * boolean which is preserved only as a back-compat alias.
   */
  tone?: AvatarTone;
  /** Legacy alias for `tone="featured"`. Kept so existing callers don't break. */
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

const TONE_BORDER: Record<AvatarTone, string> = {
  default: 'border-2 border-border',
  featured: 'border-[3px] border-gold',
  muted: '',
};

export function Avatar({ name, photoUrl, size = 48, tone, featured = false, testID }: Props) {
  const [imageFailed, setImageFailed] = useState(false);
  const effectiveTone: AvatarTone = tone ?? (featured ? 'featured' : 'default');
  const showImage = photoUrl && !imageFailed;
  const dim = { width: size, height: size, borderRadius: size / 2 };

  return (
    <View
      testID={testID ?? 'avatar-circle'}
      accessibilityRole="image"
      accessibilityLabel={name}
      style={dim}
      className={`overflow-hidden items-center justify-center bg-gold-pale ${TONE_BORDER[effectiveTone]}`}
    >
      {showImage ? (
        <Image
          source={{ uri: photoUrl! }}
          style={dim}
          accessibilityIgnoresInvertColors
          onError={() => setImageFailed(true)}
        />
      ) : (
        <Text
          className="font-display-bold text-navy"
          style={{ fontSize: TEXT_SIZE[size], lineHeight: TEXT_SIZE[size] + 2 }}
        >
          {initials(name)}
        </Text>
      )}
    </View>
  );
}
