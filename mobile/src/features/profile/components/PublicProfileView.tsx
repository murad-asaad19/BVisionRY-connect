import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Button } from '~/components/ui/Button';
import { BioMarkdown } from '~/features/profile/components/BioMarkdown';
import { ProfileHero } from '~/features/profile/components/ProfileHero';
import type { PublicProfile } from '~/features/profile/services/publicProfile.service';

export function PublicProfileView({ profile }: { profile: PublicProfile }) {
  const { t } = useTranslation();
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
              {t('profile.aboutSection')}
            </Text>
            <BioMarkdown>{profile.bio}</BioMarkdown>
          </View>
        ) : null}
        <Button
          testID="public-profile-sign-in"
          variant="primary"
          onPress={() => router.push('/(auth)/sign-in' as never)}
        >
          {t('profile.signInToConnect')}
        </Button>
      </View>
    </ScrollView>
  );
}
