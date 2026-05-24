import { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useOpportunity } from '~/features/opportunities/hooks/useOpportunity';
import { useCloseOpportunity } from '~/features/opportunities/hooks/useCloseOpportunity';
import { useAuthSession } from '~/features/auth/SessionContext';
import { ExpressInterestSheet } from './ExpressInterestSheet';
import { InterestedList } from './InterestedList';
import { QueryState } from '~/components/ui/QueryState';
import { Pill, type PillVariant } from '~/components/ui/Pill';
import { Button } from '~/components/ui/Button';
import { TopBar } from '~/components/ui/TopBar';
import { UserCard } from '~/components/ui/UserCard';
import type { OpportunityKind } from '~/features/opportunities/services/opportunities.service';

const KIND_VARIANT: Record<OpportunityKind, PillVariant> = {
  hiring: 'navy',
  seeking_role: 'solid',
  fundraising: 'success',
  investing: 'default',
  cofounder: 'warning',
  advising: 'outline',
  seeking_advisor: 'muted',
  collaboration: 'default',
};

type Props = {
  opportunityId: string;
};

export function OpportunityDetailView({ opportunityId }: Props) {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const query = useOpportunity(opportunityId);
  const close = useCloseOpportunity();
  const [sheetOpen, setSheetOpen] = useState(false);
  const [showInterested, setShowInterested] = useState(false);

  return (
    <View testID="opportunity-detail" className="flex-1 bg-surface">
      <TopBar title={t('opportunities.detail.title')} />
      <QueryState query={query}>
        {(o) => {
          const isAuthor = session?.user.id === o.authorId;
          const isClosed = o.status !== 'open';
          const locationLabel =
            [o.locationCity, o.locationCountry].filter(Boolean).join(', ') || null;

          return (
            <ScrollView contentContainerStyle={{ paddingBottom: 32 }}>
              <View className="px-4 pt-3">
                <View className="flex-row items-center gap-2 mb-2 flex-wrap">
                  <Pill variant={KIND_VARIANT[o.kind]} testID="opportunity-detail-kind">
                    {t(`opportunities.kind.${o.kind}`)}
                  </Pill>
                  {o.remoteOk ? (
                    <Pill variant="success">{t('opportunities.filter.remoteOnly')}</Pill>
                  ) : null}
                  {isClosed ? (
                    <Pill variant="muted" testID="opportunity-detail-closed">
                      {t('opportunities.detail.closedBadge')}
                    </Pill>
                  ) : null}
                  {locationLabel ? (
                    <Text className="font-body text-[11px] text-muted">{locationLabel}</Text>
                  ) : null}
                </View>

                <Text
                  testID="opportunity-detail-title"
                  className="font-display-bold text-[20px] text-navy"
                >
                  {o.title}
                </Text>
                <Text
                  testID="opportunity-detail-body"
                  className="font-body text-[13px] text-body mt-2 leading-relaxed"
                >
                  {o.body}
                </Text>

                {o.tags.length > 0 ? (
                  <View className="flex-row gap-1.5 mt-3 flex-wrap">
                    {o.tags.map((tag) => (
                      <Pill key={tag} variant="muted">
                        #{tag}
                      </Pill>
                    ))}
                  </View>
                ) : null}

                <View className="mt-4">
                  <UserCard
                    name={o.authorName}
                    handle={o.authorHandle}
                    primaryRole={o.authorPrimaryRole ?? ''}
                    photoUrl={o.authorPhotoUrl}
                    onPress={() =>
                      router.push({
                        pathname: '/(app)/p/[handle]',
                        params: { handle: o.authorHandle },
                      })
                    }
                  />
                </View>

                {/* Author actions */}
                {isAuthor ? (
                  <View className="mt-4 gap-2">
                    {o.interestedCount > 0 ? (
                      <Button
                        testID="opportunity-detail-view-interested"
                        variant="primary"
                        onPress={() => setShowInterested((v) => !v)}
                      >
                        {t('opportunities.detail.viewInterested', {
                          count: o.interestedCount,
                        })}
                      </Button>
                    ) : null}
                    {!isClosed ? (
                      <Button
                        testID="opportunity-detail-close"
                        variant="outline-danger"
                        onPress={() => close.mutate(o.id)}
                        loading={close.isPending}
                      >
                        {t('opportunities.detail.closeCta')}
                      </Button>
                    ) : null}
                  </View>
                ) : (
                  /* Viewer actions */
                  <View className="mt-4 gap-2">
                    {o.viewerHasExpressedInterest ? (
                      <View
                        testID="opportunity-detail-expressed-badge"
                        className="bg-success-bg border border-success-border rounded-[10px] px-3 py-2"
                      >
                        <Text className="font-display-bold text-[12px] text-success-text">
                          {t('opportunities.detail.expressedAlready')}
                        </Text>
                      </View>
                    ) : isClosed ? null : (
                      <Button
                        testID="opportunity-detail-express-cta"
                        variant="primary"
                        onPress={() => setSheetOpen(true)}
                      >
                        {t('opportunities.detail.expressInterestCta')}
                      </Button>
                    )}
                    {o.interestedCount > 0 ? (
                      <Text className="font-body text-[11px] text-muted text-center mt-1">
                        {t('opportunities.detail.viewInterested', {
                          count: o.interestedCount,
                        })}
                      </Text>
                    ) : null}
                  </View>
                )}
              </View>

              {/* Inline interested list for author */}
              {isAuthor && showInterested ? (
                <View className="mt-4">
                  <InterestedList opportunityId={o.id} isAuthor />
                </View>
              ) : null}
            </ScrollView>
          );
        }}
      </QueryState>

      {query.data ? (
        <ExpressInterestSheet
          visible={sheetOpen}
          opportunityId={opportunityId}
          opportunityTitle={query.data.title}
          onClose={() => setSheetOpen(false)}
        />
      ) : null}
    </View>
  );
}
