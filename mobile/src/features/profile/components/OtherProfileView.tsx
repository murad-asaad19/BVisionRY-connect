import { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useProfileByHandle } from '~/features/profile/hooks/useProfileByHandle';
import { QueryState } from '~/components/ui/QueryState';
import { useAuthSession } from '~/features/auth/SessionContext';
import { ComposeIntroSheet } from '~/features/intros/components/ComposeIntroSheet';
import { VerifiedBadge } from '~/features/verification/components/VerifiedBadge';
import { ProfileActionsMenu } from '~/features/privacy/components/ProfileActionsMenu';
import { useIsMutualMatch } from '~/features/discovery/hooks/useIsMutualMatch';
import { useDeclineCooldown } from '~/features/intros/hooks/useDeclineCooldown';
import { BioMarkdown } from '~/features/profile/components/BioMarkdown';
import { ProfileHero } from '~/features/profile/components/ProfileHero';
import { Button } from '~/components/ui/Button';
import { Banner } from '~/components/ui/Banner';

type Props = { handle: string };

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

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString(undefined, {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  } catch {
    return iso;
  }
}

export function OtherProfileView({ handle }: Props) {
  const { t } = useTranslation();
  const query = useProfileByHandle(handle);

  return (
    <QueryState
      query={query}
      isEmpty={(profile) => profile === null}
      emptyFallback={
        <View className="flex-1 items-center justify-center bg-surface px-6">
          <Text className="font-display-bold text-[18px] text-navy mb-2" testID="profile-not-found">
            {t('profile.notFoundTitle')}
          </Text>
          <Text className="font-body text-[12px] text-muted text-center">
            {t('profile.noUserWithHandle', { handle })}
          </Text>
        </View>
      }
    >
      {(profile) => profile && <Body profile={profile} />}
    </QueryState>
  );
}

type ProfileT = NonNullable<ReturnType<typeof useProfileByHandle>['data']>;

function Body({ profile }: { profile: ProfileT }) {
  const { t } = useTranslation();
  const [sheetOpen, setSheetOpen] = useState(false);
  const [sentBanner, setSentBanner] = useState(false);
  const { session } = useAuthSession();
  const isSelf = session?.user.id === profile.id;
  const mutual = useIsMutualMatch(isSelf ? undefined : profile.id);
  const cooldown = useDeclineCooldown(isSelf ? undefined : profile.id);

  return (
    <ScrollView className="flex-1 bg-surface">
      <View className="relative">
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
        {!isSelf && profile.handle && (
          <View className="absolute top-2 right-2">
            <ProfileActionsMenu targetUserId={profile.id} targetHandle={profile.handle} />
          </View>
        )}
      </View>

      {/* Hidden anchors for legacy e2e helpers. */}
      <Text testID="other-profile-name" className="absolute opacity-0" pointerEvents="none">
        {profile.name ?? ''}
      </Text>
      <Text testID="other-profile-handle" className="absolute opacity-0" pointerEvents="none">
        @{profile.handle ?? ''}
      </Text>

      {mutual.data && (
        <View className="items-center mt-3">
          <View
            testID="mutual-match-badge"
            className="self-center bg-gold-pale border border-gold rounded-full px-3 py-1"
          >
            <Text className="font-display-bold text-[11px] text-navy">
              {String.fromCharCode(0x2194)} {t('discovery.mutual')}
            </Text>
          </View>
        </View>
      )}

      {profile.headline ? (
        <Section title={t('profile.section.headline')}>
          <Text testID="other-profile-headline" className="font-body text-[13px] text-body">
            {profile.headline}
          </Text>
        </Section>
      ) : null}

      {profile.bio ? (
        <Section title={t('profile.section.bio')}>
          <View testID="other-profile-bio">
            <BioMarkdown>{profile.bio}</BioMarkdown>
          </View>
        </Section>
      ) : null}

      <Section title={t('profile.section.goal')}>
        <Text className="font-display-semibold text-[14px] text-navy capitalize">
          {profile.goal_type ? t(`discovery.goals.${profile.goal_type}`) : ''}
        </Text>
        {profile.goal_text ? (
          <Text className="font-body text-[12px] text-muted mt-1">{profile.goal_text}</Text>
        ) : null}
      </Section>

      {profile.roles?.length ? (
        <Section title={t('profile.section.roles')}>
          <View className="flex-row flex-wrap gap-2">
            {profile.roles.map((r) => (
              <View
                key={r}
                testID={`other-profile-role-${r}`}
                className={`px-2.5 py-1 rounded-full border ${
                  r === profile.primary_role ? 'bg-navy border-navy' : 'bg-white border-navy'
                }`}
              >
                <Text
                  className={`font-display-bold text-[11px] ${
                    r === profile.primary_role ? 'text-white' : 'text-navy'
                  }`}
                >
                  {t(`discovery.roles.${r}`)}
                </Text>
              </View>
            ))}
          </View>
        </Section>
      ) : null}

      {profile.city || profile.country ? (
        <Section title={t('profile.section.location')}>
          <Text className="font-body text-[12px] text-body">
            {[profile.city, profile.country].filter(Boolean).join(', ')}
          </Text>
        </Section>
      ) : null}

      <Section title={t('profile.section.verification')}>
        <VerifiedBadge username={profile.verified_github_username} />
      </Section>

      {sentBanner ? (
        <View testID="intro-sent-banner" className="mx-3 mt-3">
          <Banner variant="success">{t('profile.introSent')}</Banner>
        </View>
      ) : null}

      {!isSelf ? (
        cooldown.data?.active && cooldown.data.availableAt ? (
          <View className="mx-3 mt-4">
            <Banner variant="warning" title={t('profile.introOnHoldTitle')}>
              {t('profile.introOnHoldBody', {
                name: profile.name ?? 'They',
                date: formatDate(cooldown.data.availableAt),
              })}
            </Banner>
            <View className="bg-navy mx-0 mt-2 mb-8 p-3.5 rounded-xl">
              <Button testID="other-profile-send-intro" variant="disabled" disabled>
                {t('profile.introOnHoldButton', {
                  date: formatDate(cooldown.data.availableAt),
                })}
              </Button>
            </View>
          </View>
        ) : (
          <View className="bg-navy mx-3 mt-4 mb-8 p-3.5 rounded-xl">
            <Button
              testID="other-profile-send-intro"
              variant="gold"
              onPress={() => setSheetOpen(true)}
            >
              {t('profile.sendIntro')}
            </Button>
          </View>
        )
      ) : (
        <View className="mb-8" />
      )}

      <ComposeIntroSheet
        visible={sheetOpen}
        recipientId={profile.id}
        recipientName={profile.name ?? '?'}
        recipientHeadline={profile.headline}
        recipientHandle={profile.handle}
        recipientPhotoUrl={profile.photo_url}
        onClose={() => setSheetOpen(false)}
        onSent={() => {
          setSheetOpen(false);
          setSentBanner(true);
        }}
      />
    </ScrollView>
  );
}
