import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import * as Clipboard from 'expo-clipboard';
import { Edit, Settings, Share2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { VerifiedBadge } from '~/features/verification/components/VerifiedBadge';
import { ProfileCompletenessBanner } from '~/features/profile/components/ProfileCompletenessBanner';
import { PhotoNudgeBanner } from '~/features/profile/components/PhotoNudgeBanner';
import { BioMarkdown } from '~/features/profile/components/BioMarkdown';
import { ProfileHero } from '~/features/profile/components/ProfileHero';
import { Banner } from '~/components/ui/Banner';
import { SectionCard } from '~/components/ui/SectionCard';
import { SkeletonProfile } from '~/components/ui/Skeleton';
import { TopBar } from '~/components/ui/TopBar';
import { useToast } from '~/components/ui/Toast';
import { colors } from '~/theme/colors';
import { env } from '~/lib/env';

// Universal/app-links host for shareable web URLs. Falls back to the public
// production host when EXPO_PUBLIC_APP_LINKS_HOST is unset (dev shells).
const SHARE_HOST = env.APP_LINKS_HOST ?? 'connect.bvisionry.com';

export function ProfileView() {
  const { t } = useTranslation();
  const toast = useToast();
  const { data: profile, isLoading } = useCurrentUserProfile();

  if (isLoading || !profile) {
    return (
      <View className="flex-1 bg-surface">
        <TopBar title={t('settings.profile')} />
        <SkeletonProfile />
      </View>
    );
  }

  const onShare = async () => {
    // P1-13: copy a web URL (deep-links to the app via universal/app links when
    // installed, opens the public profile in a browser otherwise). The legacy
    // `bvisionryconnect://` scheme was useless when pasted into LinkedIn/email.
    await Clipboard.setStringAsync(`https://${SHARE_HOST}/p/${profile.handle}`);
    toast.success(t('profile.shareCopiedTitle'));
  };

  // If the completeness banner already lists "photo" as missing, suppress
  // the dedicated photo nudge so the user doesn't see two prompts about the
  // same thing. Computing this here keeps both banners in sync without the
  // child component needing to know about the parent's banner stack.
  const completenessMissing: string[] = [];
  if (!profile.photo_url) completenessMissing.push('photo');
  if (!profile.headline) completenessMissing.push('headline');
  if (!profile.bio) completenessMissing.push('bio');
  const showPhotoNudge =
    completenessMissing.length === 0 || !completenessMissing.includes('photo');

  return (
    <View className="flex-1 bg-surface">
      {/* P2-9: Edit + Share live in the TopBar — body space is reclaimed for content. */}
      <TopBar
        title={t('settings.profile')}
        actions={[
          {
            icon: <Share2 size={18} color={colors.navy} />,
            onPress: onShare,
            accessibilityLabel: t('profile.shareA11y'),
            testID: 'profile-share',
          },
          {
            icon: <Edit size={18} color={colors.navy} />,
            onPress: () => router.push('/(app)/profile/edit'),
            accessibilityLabel: t('profile.editAction'),
            testID: 'profile-edit',
          },
          {
            icon: <Settings size={18} color={colors.navy} />,
            onPress: () => router.push('/(app)/settings'),
            accessibilityLabel: t('profile.settingsA11y'),
            testID: 'profile-settings',
          },
        ]}
      />
      <ScrollView className="flex-1">
        {profile.private_mode ? (
          <View testID="private-mode-banner" className="mx-gutter mt-3">
            <Banner variant="muted" title={t('profile.privateModeTitle')}>
              {t('profile.privateModeBody')}
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

        <View className="mt-3 mx-gutter">
          <ProfileCompletenessBanner profile={profile} />
        </View>
        <PhotoNudgeBanner photoUrl={profile.photo_url ?? null} visible={showPhotoNudge} />

        {profile.headline ? (
          <SectionCard title={t('profile.section.headline')}>
            {/* P3-9: render the headline as a display-md tagline rather than a body sentence. */}
            <Text
              testID="profile-headline"
              className="font-display-bold text-display-md text-navy"
            >
              {profile.headline}
            </Text>
          </SectionCard>
        ) : null}

        {profile.bio ? (
          <SectionCard title={t('profile.section.bio')}>
            <View testID="profile-bio">
              <BioMarkdown>{profile.bio}</BioMarkdown>
            </View>
          </SectionCard>
        ) : null}

        <SectionCard title={t('profile.section.goal')}>
          <Text
            testID="profile-goal-type"
            className="font-display-semibold text-body-lg text-navy capitalize"
          >
            {profile.goal_type ? t(`discovery.goals.${profile.goal_type}`) : ''}
          </Text>
          {profile.goal_text ? (
            <Text testID="profile-goal-text" className="font-body text-body-md text-muted mt-1">
              {profile.goal_text}
            </Text>
          ) : null}
        </SectionCard>

        {profile.roles?.length ? (
          <SectionCard title={t('profile.section.roles')}>
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
                    className={`font-display-bold text-display-xs ${
                      r === profile.primary_role ? 'text-white' : 'text-navy'
                    }`}
                  >
                    {t(`discovery.roles.${r}`)}
                  </Text>
                </View>
              ))}
            </View>
          </SectionCard>
        ) : null}

        <SectionCard title={t('profile.section.location')}>
          <Text testID="profile-location" className="font-body text-body-md text-body">
            {[profile.city, profile.country].filter(Boolean).join(', ') || '—'}
          </Text>
        </SectionCard>

        <SectionCard title={t('profile.section.verification')}>
          <VerifiedBadge username={profile.verified_github_username} />
        </SectionCard>

        {/* P1-7: sign-out lives only in Settings (domain D). Removed the duplicate button. */}
        <View className="mb-8" />
      </ScrollView>
    </View>
  );
}
