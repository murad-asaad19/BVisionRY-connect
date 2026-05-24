import { View, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Button } from '~/components/ui/Button';
import { SectionCard } from '~/components/ui/SectionCard';
import { BioMarkdown } from '~/features/profile/components/BioMarkdown';
import { ProfileHero } from '~/features/profile/components/ProfileHero';
import { ProfileSignalsRow } from '~/features/profile/components/ProfileSignalsRow';
import { useAuthSession } from '~/features/auth/SessionContext';
import type { PublicProfile } from '~/features/profile/services/publicProfile.service';

export function PublicProfileView({ profile }: { profile: PublicProfile }) {
  const { t } = useTranslation();
  const { session } = useAuthSession();
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
      {/* Signals only render for authenticated viewers — the underlying RPC
          raises 'unauthenticated' for anon callers, and signals are
          relational (mutual count is meaningless to an anon visitor). */}
      {session ? <ProfileSignalsRow targetUserId={profile.id} /> : null}
      {profile.bio ? (
        <SectionCard title={t('profile.aboutSection')}>
          <BioMarkdown>{profile.bio}</BioMarkdown>
        </SectionCard>
      ) : null}
      <View className="px-gutter mt-4 mb-8">
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
