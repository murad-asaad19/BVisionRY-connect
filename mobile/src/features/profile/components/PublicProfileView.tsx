import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { Button } from '~/components/ui/Button';
import { ProfileHero } from '~/features/profile/components/ProfileHero';
import type { PublicProfile } from '~/features/profile/services/publicProfile.service';

export function PublicProfileView({ profile }: { profile: PublicProfile }) {
  return (
    <ScrollView testID="public-profile-view" className="flex-1 bg-surface">
      <ProfileHero
        name={profile.name ?? '?'}
        handle={profile.handle}
        headline={profile.headline}
        primaryRole={profile.primary_role ?? ''}
        roles={profile.roles}
        city={profile.city}
        country={profile.country}
        photoUrl={profile.photo_url}
      />
      <View className="p-4">
        {profile.bio ? (
          <View className="bg-white rounded-xl border border-border p-3 mb-4">
            <Text className="font-display-bold text-[11px] text-muted uppercase tracking-wide mb-1.5">
              About
            </Text>
            <Text className="font-body text-[12px] text-body leading-relaxed">{profile.bio}</Text>
          </View>
        ) : null}
        <Button
          testID="public-profile-sign-in"
          variant="primary"
          onPress={() => router.push('/(auth)/sign-in' as never)}
        >
          Sign in to connect
        </Button>
      </View>
    </ScrollView>
  );
}
