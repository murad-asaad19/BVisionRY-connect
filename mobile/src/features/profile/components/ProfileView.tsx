import { View, Text, Pressable, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { router } from 'expo-router';
import * as Clipboard from 'expo-clipboard';
import { useTranslation } from 'react-i18next';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { signOut } from '~/features/auth/services/auth.service';
import { VerifiedBadge } from '~/features/verification/components/VerifiedBadge';
import { ProfileCompletenessBanner } from '~/features/profile/components/ProfileCompletenessBanner';
import { PhotoNudgeBanner } from '~/features/profile/components/PhotoNudgeBanner';
import { BioMarkdown } from '~/features/profile/components/BioMarkdown';
import { ProfileHero } from '~/features/profile/components/ProfileHero';
import { Button } from '~/components/ui/Button';
import { Banner } from '~/components/ui/Banner';

type SectionProps = { title: string; children: React.ReactNode; testID?: string };

function Section({ title, children, testID }: SectionProps) {
  return (
    <View testID={testID} className="bg-white mx-3 mt-2.5 rounded-xl border border-border p-3.5">
      <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-1.5">
        {title}
      </Text>
      {children}
    </View>
  );
}

export function ProfileView() {
  const { t } = useTranslation();
  const { data: profile, isLoading } = useCurrentUserProfile();

  if (isLoading || !profile) {
    return (
      <View className="flex-1 items-center justify-center bg-surface">
        <ActivityIndicator color="#0f3460" />
      </View>
    );
  }

  const onShare = async () => {
    await Clipboard.setStringAsync(`bvisionryconnect://p/${profile.handle}`);
    Alert.alert(t('profile.shareCopiedTitle'), t('profile.shareCopiedBody'));
  };

  return (
    <ScrollView className="flex-1 bg-surface">
      {profile.private_mode ? (
        <View testID="private-mode-banner" className="mx-3 mt-3">
          <Banner variant="muted" title="Private mode is on">
            You&apos;re hidden from feed, Daily matches, and search.
          </Banner>
        </View>
      ) : null}
      <ProfileHero
        name={profile.name ?? '?'}
        handle={profile.handle ?? '?'}
        headline={profile.headline}
        primaryRole={profile.primary_role ?? ''}
        roles={profile.roles ?? []}
        city={profile.city}
        country={profile.country}
        photoUrl={profile.photo_url ?? null}
      />

      {/* Hidden anchors for legacy e2e helpers. */}
      <Text testID="profile-name" className="absolute opacity-0" pointerEvents="none">
        {profile.name ?? ''}
      </Text>
      <Text testID="profile-handle" className="absolute opacity-0" pointerEvents="none">
        @{profile.handle ?? ''}
      </Text>

      <View className="flex-row justify-end mx-3 mt-3 gap-2">
        <Pressable
          testID="profile-share"
          onPress={onShare}
          accessibilityRole="button"
          accessibilityLabel={t('profile.shareA11y')}
          className="bg-white border border-border px-3 py-2 rounded-lg"
        >
          <Text className="font-display-semibold text-[12px] text-navy">{t('profile.share')}</Text>
        </Pressable>
        <Pressable
          testID="profile-edit"
          onPress={() => router.push('/(app)/profile/edit')}
          className="bg-white border border-border px-3 py-2 rounded-lg"
        >
          <Text className="font-display-semibold text-[12px] text-navy">Edit</Text>
        </Pressable>
      </View>

      <View className="mt-2">
        <ProfileCompletenessBanner profile={profile} />
        <PhotoNudgeBanner photoUrl={profile.photo_url ?? null} />
      </View>

      {profile.headline ? (
        <Section title="Headline">
          <Text testID="profile-headline" className="font-body text-[13px] text-body">
            {profile.headline}
          </Text>
        </Section>
      ) : null}

      {profile.bio ? (
        <Section title="Bio">
          <View testID="profile-bio">
            <BioMarkdown>{profile.bio}</BioMarkdown>
          </View>
        </Section>
      ) : null}

      <Section title="Goal">
        <Text
          testID="profile-goal-type"
          className="font-display-semibold text-[14px] text-navy capitalize"
        >
          {profile.goal_type?.replace(/_/g, ' ')}
        </Text>
        {profile.goal_text ? (
          <Text testID="profile-goal-text" className="font-body text-[12px] text-muted mt-1">
            {profile.goal_text}
          </Text>
        ) : null}
      </Section>

      {profile.roles?.length ? (
        <Section title="Roles">
          <View className="flex-row flex-wrap gap-2">
            {profile.roles.map((r) => (
              <View
                key={r}
                testID={`profile-role-${r}`}
                className={`px-2.5 py-1 rounded-full border ${
                  r === profile.primary_role ? 'bg-navy border-navy' : 'bg-white border-navy'
                }`}
              >
                <Text
                  className={`font-display-bold text-[11px] ${
                    r === profile.primary_role ? 'text-white' : 'text-navy'
                  }`}
                >
                  {r}
                </Text>
              </View>
            ))}
          </View>
        </Section>
      ) : null}

      <Section title="Location">
        <Text testID="profile-location" className="font-body text-[12px] text-body">
          {[profile.city, profile.country].filter(Boolean).join(', ') || '—'}
        </Text>
      </Section>

      <Section title="Verification">
        <VerifiedBadge username={profile.verified_github_username} />
      </Section>

      <View className="mx-3 mt-4 mb-8">
        <Button
          testID="profile-sign-out"
          variant="outline"
          onPress={() => signOut().catch(console.warn)}
        >
          Sign out
        </Button>
      </View>
    </ScrollView>
  );
}
