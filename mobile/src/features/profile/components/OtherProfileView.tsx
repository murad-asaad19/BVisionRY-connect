import { useMemo, useState } from 'react';
import { View, Text, ScrollView, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useProfileByHandle } from '~/features/profile/hooks/useProfileByHandle';
import { QueryState } from '~/components/ui/QueryState';
import { useAuthSession } from '~/features/auth/SessionContext';
import { ComposeIntroSheet } from '~/features/intros/components/ComposeIntroSheet';
import {
  WarmIntroComposeSheet,
  type WarmIntroComposeTarget,
} from '~/features/intros/components/WarmIntroComposeSheet';
import { useWarmIntroSuggestions } from '~/features/intros/hooks/useWarmIntroSuggestions';
import { VerifiedBadge } from '~/features/verification/components/VerifiedBadge';
import { ProfileActionsMenu } from '~/features/privacy/components/ProfileActionsMenu';
import { useIsMutualMatch } from '~/features/discovery/hooks/useIsMutualMatch';
import { useDeclineCooldown } from '~/features/intros/hooks/useDeclineCooldown';
import { BioMarkdown } from '~/features/profile/components/BioMarkdown';
import { ProfileHero } from '~/features/profile/components/ProfileHero';
import { ProfileSignalsRow } from '~/features/profile/components/ProfileSignalsRow';
import { Button } from '~/components/ui/Button';
import { Banner } from '~/components/ui/Banner';
import { SectionCard } from '~/components/ui/SectionCard';
import { useUpcomingSlots } from '~/features/office-hours/hooks/useUpcomingSlots';
import { UpcomingSlotsList } from '~/features/office-hours/components/UpcomingSlotsList';
import { BookSlotSheet } from '~/features/office-hours/components/BookSlotSheet';
import type { UpcomingSlot } from '~/features/office-hours/services/officeHours.service';

/** First name of a "First Last" string (falls back to the whole string). */
function firstName(name: string | null | undefined): string {
  if (!name) return '';
  const trimmed = name.trim();
  if (!trimmed) return '';
  return trimmed.split(/\s+/)[0] ?? trimmed;
}

type Props = { handle: string };

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
          <Text className="font-display-bold text-display-md text-navy mb-2" testID="profile-not-found">
            {t('profile.notFoundTitle')}
          </Text>
          <Text className="font-body text-body-md text-muted text-center">
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
  const [warmComposeTarget, setWarmComposeTarget] = useState<WarmIntroComposeTarget | null>(null);
  const [sentBanner, setSentBanner] = useState(false);
  const [bookSlotTarget, setBookSlotTarget] = useState<UpcomingSlot | null>(null);
  const { session } = useAuthSession();
  const isSelf = session?.user.id === profile.id;
  const mutual = useIsMutualMatch(isSelf ? undefined : profile.id);
  const cooldown = useDeclineCooldown(isSelf ? undefined : profile.id);
  // Warm-intro suggestions already encode the rules we need for the banner:
  // viewer has a mutual with the target AND no existing intros row with the
  // target (the RPC excludes those). If this profile is in the list, the
  // banner is safe to show.
  const warmSuggestions = useWarmIntroSuggestions();
  const warmSuggestion = useMemo(
    () => (warmSuggestions.data ?? []).find((s) => s.targetId === profile.id) ?? null,
    [warmSuggestions.data, profile.id]
  );
  const upcomingSlots = useUpcomingSlots(isSelf ? undefined : profile.id);
  const hasOpenSlots = (upcomingSlots.data?.length ?? 0) > 0;

  // P1-8: when not self, the bottom of the scroll view sits below a fixed
  // sticky CTA. Pad the scroll content so the last section never hides
  // underneath it (sticky bar ≈ 72pt including border + safe inset).
  const showStickyCta = !isSelf;
  const STICKY_CTA_PAD = 96;

  return (
    <View className="flex-1 bg-surface">
      <ScrollView
        className="flex-1"
        contentContainerStyle={{ paddingBottom: showStickyCta ? STICKY_CTA_PAD : 24 }}
      >
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
              <Text className="font-display-bold text-display-xs text-navy">
                {String.fromCharCode(0x2194)} {t('discovery.mutual')}
              </Text>
            </View>
          </View>
        )}

        {!isSelf ? <ProfileSignalsRow targetUserId={profile.id} /> : null}

        {!isSelf && warmSuggestion ? (
          <View testID="warm-intro-profile-banner" className="mx-gutter mt-3">
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('intros.warm.profileBannerCta', {
                firstName: firstName(warmSuggestion.topMutualName),
              })}
              onPress={() =>
                setWarmComposeTarget({
                  mutualId: warmSuggestion.topMutualId,
                  mutualName: warmSuggestion.topMutualName,
                  mutualHandle: warmSuggestion.topMutualHandle,
                  mutualPhotoUrl: null,
                  targetId: profile.id,
                  targetName: profile.name ?? '?',
                  targetHandle: profile.handle,
                })
              }
            >
              <Banner
                variant="info"
                title={t('intros.warm.profileBanner', { mutualName: warmSuggestion.topMutualName })}
              >
                <Text className="font-display-bold text-display-xs text-info-text">
                  {t('intros.warm.profileBannerCta', {
                    firstName: firstName(warmSuggestion.topMutualName),
                  })}
                </Text>
              </Banner>
            </Pressable>
          </View>
        ) : null}

        {!isSelf && hasOpenSlots ? (
          <SectionCard title={t('officeHours.profile.sectionTitle')} testID="office-hours-section">
            <UpcomingSlotsList hostId={profile.id} onPickSlot={(s) => setBookSlotTarget(s)} />
          </SectionCard>
        ) : null}

        {profile.headline ? (
          <SectionCard title={t('profile.section.headline')}>
            {/* P3-9: headline reads as a display-md tagline, not a body sentence. */}
            <Text
              testID="other-profile-headline"
              className="font-display-bold text-display-md text-navy"
            >
              {profile.headline}
            </Text>
          </SectionCard>
        ) : null}

        {profile.bio ? (
          <SectionCard title={t('profile.section.bio')}>
            <View testID="other-profile-bio">
              <BioMarkdown>{profile.bio}</BioMarkdown>
            </View>
          </SectionCard>
        ) : null}

        <SectionCard title={t('profile.section.goal')}>
          <Text className="font-display-semibold text-body-lg text-navy capitalize">
            {profile.goal_type ? t(`discovery.goals.${profile.goal_type}`) : ''}
          </Text>
          {profile.goal_text ? (
            <Text className="font-body text-body-md text-muted mt-1">{profile.goal_text}</Text>
          ) : null}
        </SectionCard>

        {profile.roles?.length ? (
          <SectionCard title={t('profile.section.roles')}>
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

        {profile.city || profile.country ? (
          <SectionCard title={t('profile.section.location')}>
            <Text className="font-body text-body-md text-body">
              {[profile.city, profile.country].filter(Boolean).join(', ')}
            </Text>
          </SectionCard>
        ) : null}

        <SectionCard title={t('profile.section.verification')}>
          <VerifiedBadge username={profile.verified_github_username} />
        </SectionCard>

        {sentBanner ? (
          <View testID="intro-sent-banner" className="mx-gutter mt-3">
            <Banner variant="success">{t('profile.introSent')}</Banner>
          </View>
        ) : null}

        {!isSelf && cooldown.data?.active && cooldown.data.availableAt ? (
          <View className="mx-gutter mt-4">
            <Banner variant="warning" title={t('profile.introOnHoldTitle')}>
              {t('profile.introOnHoldBody', {
                name: profile.name ?? 'They',
                date: formatDate(cooldown.data.availableAt),
              })}
            </Banner>
          </View>
        ) : null}
      </ScrollView>

      {/* P1-8: sticky bottom CTA replaces the bespoke `bg-navy ... rounded-xl`
          wrapper. A gold/primary button reads fine on white with a border-top
          divider, and the CTA stays in-thumb regardless of scroll position. */}
      {showStickyCta ? (
        <View
          style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}
          className="px-gutter py-3 border-t border-border bg-white"
        >
          {cooldown.data?.active && cooldown.data.availableAt ? (
            <Button testID="other-profile-send-intro" variant="disabled" disabled>
              {t('profile.introOnHoldButton', {
                date: formatDate(cooldown.data.availableAt),
              })}
            </Button>
          ) : (
            <Button
              testID="other-profile-send-intro"
              variant="primary"
              onPress={() => setSheetOpen(true)}
            >
              {t('profile.sendIntro')}
            </Button>
          )}
        </View>
      ) : null}

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

      <WarmIntroComposeSheet
        visible={warmComposeTarget !== null}
        context={warmComposeTarget}
        onClose={() => setWarmComposeTarget(null)}
        onSent={() => setWarmComposeTarget(null)}
      />

      <BookSlotSheet
        visible={bookSlotTarget !== null}
        hostId={profile.id}
        hostName={profile.name ?? '?'}
        slot={bookSlotTarget}
        onClose={() => setBookSlotTarget(null)}
        onBooked={() => setBookSlotTarget(null)}
      />
    </View>
  );
}
