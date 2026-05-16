import { View, Text, Image } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Pill } from '~/components/ui/Pill';

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

export function ProfileHero({
  name,
  handle,
  headline,
  primaryRole,
  roles,
  city,
  country,
  photoUrl,
}: Props) {
  return (
    <LinearGradient
      colors={['#0f3460', '#1a4a80']}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={{ paddingTop: 20, paddingBottom: 18, paddingHorizontal: 16 }}
    >
      {/* Gold radial overlay approximation: ellipse gradient layered on top */}
      <LinearGradient
        colors={['rgba(255,193,7,0.25)', 'transparent']}
        start={{ x: 0.5, y: 0 }}
        end={{ x: 0.5, y: 1 }}
        style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 140 }}
      />

      <View className="items-center">
        <LinearGradient
          colors={['#ffe187', '#ffc107']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={{
            width: 82,
            height: 82,
            borderRadius: 41,
            alignItems: 'center',
            justifyContent: 'center',
            borderWidth: 3,
            borderColor: '#ffffff',
            shadowColor: '#ffc107',
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
            <Text className="font-display-bold text-[32px] text-navy">
              {(name?.[0] ?? '?').toUpperCase()}
            </Text>
          )}
        </LinearGradient>

        <Text testID="profile-hero-name" className="font-display-bold text-[18px] text-white">
          {name}
        </Text>
        <Text testID="profile-hero-handle" className="font-body text-[12px] text-gold-light">
          @{handle}
        </Text>
        {headline ? (
          <Text
            className="font-body text-[12px] text-gold-light text-center mt-1 px-3"
            numberOfLines={2}
          >
            {headline}
          </Text>
        ) : null}

        <View className="flex-row gap-1.5 mt-2.5 flex-wrap justify-center">
          {roles.map((r) => (
            <Pill key={r} variant={r === primaryRole ? 'solid' : 'outline'}>
              {r}
            </Pill>
          ))}
        </View>

        {city || country ? (
          <Text className="font-body text-[11px] text-white/80 mt-2">
            {city ? city : ''}
            {city && country ? ', ' : ''}
            {country ? country : ''}
          </Text>
        ) : null}
      </View>
    </LinearGradient>
  );
}
