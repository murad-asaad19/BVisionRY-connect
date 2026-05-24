import { useMemo, useState } from 'react';
import { View, Text, ScrollView, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { QueryState } from '~/components/ui/QueryState';
import { Button } from '~/components/ui/Button';
import { Banner } from '~/components/ui/Banner';
import { Pill } from '~/components/ui/Pill';
import { TopBar } from '~/components/ui/TopBar';
import { IntroStateBadge } from './IntroStateBadge';
import { WarmIntroForwardSheet } from '~/features/intros/components/WarmIntroForwardSheet';
import { useIntroById } from '~/features/intros/hooks/useIntroById';
import { useAcceptIntro } from '~/features/intros/hooks/useAcceptIntro';
import { useDeclineIntro } from '~/features/intros/hooks/useDeclineIntro';
import { useAuthSession } from '~/features/auth/SessionContext';
import { IntroExpiredError } from '~/features/intros/services/intros.service';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

/** First name (or the whole string if there's no whitespace). */
function firstName(name: string | null | undefined): string {
  if (!name) return '';
  const trimmed = name.trim();
  if (!trimmed) return '';
  return trimmed.split(/\s+/)[0] ?? trimmed;
}

type ProfileLite = Pick<
  Database['public']['Tables']['profiles']['Row'],
  'id' | 'name' | 'handle' | 'photo_url'
>;

function useProfileLite(id: string | null | undefined) {
  return useQuery({
    queryKey: ['profile-by-id', id],
    enabled: !!id,
    staleTime: 60_000,
    queryFn: async (): Promise<ProfileLite | null> => {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, handle, photo_url')
        .eq('id', id!)
        .single();
      if (error) {
        if (error.code === 'PGRST116') return null;
        throw new Error(error.message);
      }
      return data;
    },
  });
}

type Props = { id: string };

export function IntroDetailView({ id }: Props) {
  const { t } = useTranslation();
  const introQuery = useIntroById(id);
  const acceptMutation = useAcceptIntro();
  const declineMutation = useDeclineIntro();
  const { session } = useAuthSession();
  const [banner, setBanner] = useState<string | null>(null);

  return (
    <QueryState
      query={introQuery}
      isEmpty={(data) => data === null}
      emptyFallback={
        <View className="flex-1 items-center justify-center bg-surface px-gutter">
          <Text className="font-body text-body-lg text-body mb-2">{t('intros.detail.notFound')}</Text>
          <Pressable
            onPress={() => router.back()}
            className="bg-white px-4 py-2 rounded-lg border border-border active:opacity-80"
          >
            <Text className="font-body text-body-lg text-body">{t('intros.detail.back')}</Text>
          </Pressable>
        </View>
      }
    >
      {(intro) =>
        intro && (
          <Body
            intro={intro}
            myId={session?.user.id ?? null}
            banner={banner}
            onAccept={async () => {
              try {
                await acceptMutation.mutateAsync(intro.id);
                setBanner(t('intros.detail.accepted'));
              } catch (e) {
                if (e instanceof IntroExpiredError) {
                  setBanner(t('intros.compose.errorExpired'));
                } else {
                  setBanner(t('intros.detail.acceptFailed'));
                }
              }
            }}
            onDecline={async () => {
              try {
                await declineMutation.mutateAsync(intro.id);
                setBanner(t('intros.detail.declined'));
              } catch (e) {
                if (e instanceof IntroExpiredError) {
                  setBanner(t('intros.compose.errorExpired'));
                } else {
                  setBanner(t('intros.detail.declineFailed'));
                }
              }
            }}
            working={acceptMutation.isPending || declineMutation.isPending}
          />
        )
      }
    </QueryState>
  );
}

type IntroT = NonNullable<ReturnType<typeof useIntroById>['data']>;

function Body({
  intro,
  myId,
  banner,
  onAccept,
  onDecline,
  working,
}: {
  intro: IntroT;
  myId: string | null;
  banner: string | null;
  onAccept: () => void;
  onDecline: () => void;
  working: boolean;
}) {
  const { t } = useTranslation();
  const senderQuery = useProfileLite(intro.sender_id);
  const recipientQuery = useProfileLite(intro.recipient_id);
  // For warm_request intros: warm_target_id points at the third-party
  // the asker wants to be introduced to (rendered in the Forward CTA).
  // For warm_forward intros: warm_target_id back-points at the mutual
  // who forwarded (rendered as "Via Alice").
  const warmReferenceQuery = useProfileLite(intro.warm_target_id ?? null);
  const isSender = myId === intro.sender_id;
  const counterpart = isSender ? recipientQuery.data : senderQuery.data;
  const counterpartLabel = isSender ? t('intros.detail.to') : t('intros.detail.from');
  // Compute expiry against a stable timestamp captured per render so a long-lived
  // mounted view doesn't flip mid-press; QueryState re-fetches will refresh it.
  const isExpired = useMemo(() => new Date(intro.expires_at).getTime() < Date.now(), [intro.expires_at]);
  const isWarmRequest = intro.kind === 'warm_request';
  const isWarmForward = intro.kind === 'warm_forward';
  const isRecipient = myId === intro.recipient_id;
  // Recipient of a delivered warm_request → can forward instead of (or in addition to) decline.
  const canForward =
    isWarmRequest && isRecipient && intro.state === 'delivered' && !isExpired;
  // Standard accept/decline still applies for direct + warm_forward intros (the
  // forwarded intro behaves like a normal one from the target's perspective).
  const canAct = isRecipient && intro.state === 'delivered' && !isExpired && !isWarmRequest;

  const [forwardOpen, setForwardOpen] = useState(false);

  const noteCaption = counterpart?.name
    ? t('intros.detail.says', { name: counterpart.name.toUpperCase() })
    : t('intros.detail.note');

  return (
    <ScrollView className="flex-1 bg-surface">
      <TopBar back title={t('intros.detail.title')} />
      <View className="px-gutter pt-4 pb-8">
        {banner && (
          <View testID="intro-banner" className="mb-4">
            <Banner variant="info">{banner}</Banner>
          </View>
        )}

        {isWarmRequest ? (
          <View testID="intro-warm-request-pill" className="mb-3">
            <Pill variant="navy">{t('intros.warm.kindWarmRequestBadge')}</Pill>
          </View>
        ) : null}

        {isWarmForward && warmReferenceQuery.data?.name ? (
          <View testID="intro-warm-forward-banner" className="mb-3">
            <Banner variant="info">
              {t('intros.warm.viaForwarder', { name: warmReferenceQuery.data.name })}
            </Banner>
          </View>
        ) : null}

        <View className="flex-row items-center justify-between mb-6">
          <View className="flex-row items-center flex-1">
            <AvatarCircle
              name={counterpart?.name ?? '?'}
              photoUrl={counterpart?.photo_url ?? null}
              size={64}
            />
            <View className="ml-3 flex-1">
              <Text className="font-body text-body-sm text-muted">{counterpartLabel}</Text>
              <Text
                className="font-display-bold text-display-md text-navy"
                numberOfLines={1}
                testID="intro-counterpart-name"
              >
                {counterpart?.name ?? '...'}
              </Text>
              <Text className="font-body text-body-sm text-muted" numberOfLines={1}>
                @{counterpart?.handle ?? '?'}
              </Text>
              {isWarmForward && warmReferenceQuery.data?.name ? (
                <Text
                  testID="intro-warm-forward-via"
                  className="font-body text-body-xs text-muted mt-0.5"
                  numberOfLines={1}
                >
                  {t('intros.warm.kindWarmForwardVia', { name: warmReferenceQuery.data.name })}
                </Text>
              ) : null}
            </View>
          </View>
          <IntroStateBadge
            state={intro.state}
            audience={isSender ? 'sender' : 'recipient'}
            expiresAt={intro.expires_at}
          />
        </View>

        <View className="mb-4">
          <Banner variant="muted" title={noteCaption}>
            <Text testID="intro-note" className="font-body text-body-md text-body">
              {intro.note}
            </Text>
          </Banner>
        </View>

        {/* Expiry hint sits above the silent-decline hint so the recipient sees
            the gating reason first if both apply. */}
        {!isSender && intro.state === 'delivered' && isExpired ? (
          <View testID="intro-expired-hint" className="mb-3">
            <Banner variant="muted">{t('intros.detail.expiredHint')}</Banner>
          </View>
        ) : null}

        {!isSender && intro.state === 'delivered' && !isExpired && !isWarmRequest ? (
          <Text className="font-body text-body-xs text-muted mb-3">
            {t('intros.detail.declineSilent')}
          </Text>
        ) : null}

        {canAct && (
          <View className="flex-row gap-3">
            <View className="flex-1">
              <Button
                testID="intro-decline"
                variant="outline"
                onPress={onDecline}
                disabled={working}
              >
                {t('intros.detail.decline')}
              </Button>
            </View>
            <View className="flex-1">
              <Button
                testID="intro-accept"
                variant="primary"
                onPress={onAccept}
                disabled={working}
                loading={working}
              >
                {t('intros.detail.accept')}
              </Button>
            </View>
          </View>
        )}

        {canForward && (
          <View className="flex-row gap-3">
            <View className="flex-1">
              <Button
                testID="intro-decline"
                variant="outline"
                onPress={onDecline}
                disabled={working}
              >
                {t('intros.detail.decline')}
              </Button>
            </View>
            <View className="flex-1">
              <Button
                testID="intro-warm-forward"
                variant="primary"
                onPress={() => setForwardOpen(true)}
                disabled={working}
              >
                {t('intros.warm.forwardTitle', {
                  targetName: warmReferenceQuery.data?.name ?? '…',
                })}
              </Button>
            </View>
          </View>
        )}
      </View>

      {canForward && warmReferenceQuery.data ? (
        <WarmIntroForwardSheet
          visible={forwardOpen}
          introId={intro.id}
          askerFirstName={firstName(senderQuery.data?.name) || '…'}
          targetName={warmReferenceQuery.data.name ?? '…'}
          targetFirstName={firstName(warmReferenceQuery.data.name) || '…'}
          targetHandle={warmReferenceQuery.data.handle}
          targetPhotoUrl={warmReferenceQuery.data.photo_url}
          originalNote={intro.note}
          onClose={() => setForwardOpen(false)}
          onForwarded={() => setForwardOpen(false)}
        />
      ) : null}
    </ScrollView>
  );
}
