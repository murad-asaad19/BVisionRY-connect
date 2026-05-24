import { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { useOpportunity } from '~/features/opportunities/hooks/useOpportunity';
import { useCloseOpportunity } from '~/features/opportunities/hooks/useCloseOpportunity';
import { useAuthSession } from '~/features/auth/SessionContext';
import { ExpressInterestSheet } from './ExpressInterestSheet';
import { InterestedList } from './InterestedList';
import { AuthorRow } from './OpportunityCard';
import { QueryState } from '~/components/ui/QueryState';
import { Pill } from '~/components/ui/Pill';
import { Button } from '~/components/ui/Button';
import { TopBar } from '~/components/ui/TopBar';
import { useConfirm } from '~/components/ui/ConfirmDialog';
import { useToast } from '~/components/ui/Toast';

type Props = {
  opportunityId: string;
};

/**
 * Detail view. Per audit P2-6 the kind is a single neutral navy chip;
 * semantic chips (`remote`, `closed`) keep their semantic palette so they
 * read as status not category. Per audit polish, the primary CTA (Express
 * interest) is anchored to a sticky footer rather than scrolling inline.
 */
export function OpportunityDetailView({ opportunityId }: Props) {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const query = useOpportunity(opportunityId);
  const close = useCloseOpportunity();
  const confirm = useConfirm();
  const toast = useToast();
  const [sheetOpen, setSheetOpen] = useState(false);
  const [showInterested, setShowInterested] = useState(false);

  const handleClose = async (id: string) => {
    const ok = await confirm({
      title: t('opportunities.detail.closeConfirmTitle'),
      body: t('opportunities.detail.closeConfirmBody'),
      confirmLabel: t('opportunities.detail.closeConfirmCta'),
      destructive: true,
      onConfirm: async () => {
        await close.mutateAsync(id);
      },
    });
    if (ok) toast.success(t('opportunities.detail.closeSuccess'));
  };

  return (
    <View testID="opportunity-detail" className="flex-1 bg-surface">
      <TopBar back title={t('opportunities.detail.title')} />
      <QueryState query={query}>
        {(o) => {
          const isAuthor = session?.user.id === o.authorId;
          const isClosed = o.status !== 'open';
          const locationLabel =
            [o.locationCity, o.locationCountry].filter(Boolean).join(', ') || null;
          // Reserve room for the sticky CTA when one is visible. Author closing
          // path also gets the sticky treatment so the bottom of the scroll
          // never overlaps the footer.
          const showStickyCta =
            isAuthor
              ? !isClosed
              : !o.viewerHasExpressedInterest && !isClosed;

          return (
            <>
              <ScrollView
                contentContainerStyle={{ paddingBottom: showStickyCta ? 96 : 32 }}
              >
                <View className="px-gutter pt-3">
                  <View className="flex-row items-center gap-2 mb-2 flex-wrap">
                    <Pill variant="navy" testID="opportunity-detail-kind">
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
                      <Text className="font-body text-body-sm text-muted">{locationLabel}</Text>
                    ) : null}
                  </View>

                  <Text
                    testID="opportunity-detail-title"
                    className="font-display-bold text-display-lg text-navy"
                  >
                    {o.title}
                  </Text>
                  <Text
                    testID="opportunity-detail-body"
                    className="font-body text-display-sm text-body mt-2 leading-relaxed"
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

                  <AuthorRow
                    name={o.authorName}
                    handle={o.authorHandle}
                    primaryRole={o.authorPrimaryRole}
                    photoUrl={o.authorPhotoUrl}
                    onPress={() =>
                      router.push({
                        pathname: '/p/[handle]',
                        params: { handle: o.authorHandle },
                      })
                    }
                    testID="opportunity-detail-author"
                  />

                  {/* Author secondary actions (view interested, view count) */}
                  {isAuthor && o.interestedCount > 0 ? (
                    <View className="mt-4">
                      <Button
                        testID="opportunity-detail-view-interested"
                        variant="outline"
                        onPress={() => setShowInterested((v) => !v)}
                      >
                        {t('opportunities.detail.viewInterested', {
                          count: o.interestedCount,
                        })}
                      </Button>
                    </View>
                  ) : null}

                  {/* Viewer status badge */}
                  {!isAuthor && o.viewerHasExpressedInterest ? (
                    <View
                      testID="opportunity-detail-expressed-badge"
                      className="bg-success-bg border border-success-border rounded-[10px] px-3 py-2 mt-4"
                    >
                      <Text className="font-display-bold text-body-md text-success-text">
                        {t('opportunities.detail.expressedAlready')}
                      </Text>
                    </View>
                  ) : null}

                  {/* Interested count footer for non-authors */}
                  {!isAuthor && o.interestedCount > 0 ? (
                    <Text className="font-body text-body-sm text-muted text-center mt-3">
                      {t('opportunities.detail.viewInterested', {
                        count: o.interestedCount,
                      })}
                    </Text>
                  ) : null}
                </View>

                {/* Inline interested list for author */}
                {isAuthor && showInterested ? (
                  <View className="mt-4">
                    <InterestedList opportunityId={o.id} isAuthor />
                  </View>
                ) : null}
              </ScrollView>

              {/* Sticky CTA — primary action lives below the fold so the user
                  never has to scroll to act. */}
              {showStickyCta ? (
                <View className="absolute bottom-0 left-0 right-0 px-gutter py-3 border-t border-border bg-white">
                  {isAuthor ? (
                    <Button
                      testID="opportunity-detail-close"
                      variant="outline-danger"
                      fullWidth
                      onPress={() => handleClose(o.id)}
                      loading={close.isPending}
                    >
                      {t('opportunities.detail.closeCta')}
                    </Button>
                  ) : (
                    <Button
                      testID="opportunity-detail-express-cta"
                      variant="primary"
                      fullWidth
                      onPress={() => setSheetOpen(true)}
                    >
                      {t('opportunities.detail.expressInterestCta')}
                    </Button>
                  )}
                </View>
              ) : null}
            </>
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
