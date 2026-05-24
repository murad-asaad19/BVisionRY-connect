import { memo } from 'react';
import { View, Text, Image } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useTranslation } from 'react-i18next';
import { Pill } from '~/components/ui/Pill';
import { colors } from '~/theme/colors';

const AVATAR_SIZE = 76;

type Props = {
  name: string;
  handle: string;
  headline?: string | null;
  primaryRole: string;
  roles: string[];
  city?: string | null;
  country?: string | null;
  photoUrl: string | null;
};

function ProfileHeroImpl({
  name,
  handle,
  headline,
  primaryRole,
  roles,
  city,
  country,
  photoUrl,
}: Props) {
  const { t } = useTranslation();
  return (
    <LinearGradient
      colors={[colors.navy, colors.navyLight]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={{ paddingTop: 20, paddingBottom: 18, paddingHorizontal: 16 }}
    >
      {/* Dimmed gold radial overlay (P1-4) — kept as subtle warmth, not a competing accent. */}
      <LinearGradient
        colors={['rgba(255,193,7,0.12)', 'transparent']}
        start={{ x: 0.5, y: 0 }}
        end={{ x: 0.5, y: 1 }}
        style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 140 }}
      />

      <View className="items-center">
        <LinearGradient
          colors={[colors.goldLight, colors.gold]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={{
            width: 82,
            height: 82,
            borderRadius: 41,
            alignItems: 'center',
            justifyContent: 'center',
            borderWidth: 3,
            borderColor: colors.white,
            shadowColor: colors.gold,
            shadowOpacity: 0.6,
            shadowRadius: 3,
            marginBottom: 8,
          }}
        >
          {photoUrl ? (
            <Image
              source={{ uri: photoUrl }}
              style={{ width: AVATAR_SIZE, height: AVATAR_SIZE, borderRadius: AVATAR_SIZE / 2 }}
            />
          ) : (
            <Text className="font-display-bold text-display-xl text-navy">
              {(name?.[0] ?? '?').toUpperCase()}
            </Text>
          )}
        </LinearGradient>

        <Text testID="profile-hero-name" className="font-display-bold text-display-md text-white">
          {name}
        </Text>
        {/* P1-4: handle, headline, location use white (not gold-light) for AA contrast on navy gradient. */}
        <Text testID="profile-hero-handle" className="font-body text-body-md text-white">
          @{handle}
        </Text>
        {headline ? (
          <Text
            className="font-body text-body-md text-white text-center mt-1 px-3"
            numberOfLines={2}
          >
            {headline}
          </Text>
        ) : null}

        <View className="flex-row gap-1.5 mt-2.5 flex-wrap justify-center">
          {roles.map((r) => (
            <Pill key={r} variant={r === primaryRole ? 'solid' : 'outline'}>
              {t(`discovery.roles.${r}`)}
            </Pill>
          ))}
        </View>

        {city || country ? (
          <Text className="font-body text-body-sm text-white/90 mt-2">
            {city ? city : ''}
            {city && country ? ', ' : ''}
            {country ? country : ''}
          </Text>
        ) : null}
      </View>
    </LinearGradient>
  );
}

// Hero re-renders on every banner toggle; the rendered hierarchy here is
// expensive (two LinearGradients + an Image). Compare the actual props rather
// than the default shallow check so an unstable `roles` array reference
// doesn't bust the memo when the array contents are identical.
function arraysEqual<T>(a: readonly T[], b: readonly T[]): boolean {
  if (a === b) return true;
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

export const ProfileHero = memo(ProfileHeroImpl, (prev, next) => {
  return (
    prev.name === next.name &&
    prev.handle === next.handle &&
    prev.headline === next.headline &&
    prev.primaryRole === next.primaryRole &&
    prev.city === next.city &&
    prev.country === next.country &&
    prev.photoUrl === next.photoUrl &&
    arraysEqual(prev.roles, next.roles)
  );
});
