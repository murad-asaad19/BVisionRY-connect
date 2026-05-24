import { useState } from 'react';
import { View, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Pill } from '~/components/ui/Pill';
import { useProfileSignals } from '~/features/profile/hooks/useProfileSignals';
import { MutualConnectionsModal } from '~/features/profile/components/MutualConnectionsModal';

type Props = {
  targetUserId: string;
  /** Optional override for tests; production code reads from the hook. */
  testID?: string;
};

/**
 * Compact row of trust-signal chips shown between the profile hero and
 * the bio section. Renders nothing when both signals are absent so the
 * profile layout stays clean on a brand-new account.
 *
 * Tapping the mutual-count pill opens a modal listing the top 5 mutual
 * connections. The rating pill is not tappable — it's a passive
 * summary; the underlying review list isn't shown to other users (we
 * deliberately avoid surfacing individual review notes on a public
 * profile to protect reviewers and prevent retaliation).
 */
export function ProfileSignalsRow({ targetUserId, testID }: Props) {
  const { t } = useTranslation();
  const [modalOpen, setModalOpen] = useState(false);
  const query = useProfileSignals(targetUserId);

  // Loading / error / disabled → render nothing. We never want a
  // half-rendered signal row that flashes in and out, and the lack of
  // signals on a brand-new account is the common case.
  if (!query.data) return null;

  const { mutualConnectionCount, mutualTopUserIds, avgMeetingRating, totalMeetingReviews } =
    query.data;

  const showMutual = mutualConnectionCount > 0;
  const showRating = avgMeetingRating !== null && totalMeetingReviews >= 3;

  if (!showMutual && !showRating) return null;

  return (
    <>
      <View
        testID={testID ?? 'profile-signals-row'}
        className="flex-row flex-wrap gap-1.5 mx-3 mt-2.5"
      >
        {showMutual ? (
          <Pressable
            testID="profile-signals-mutual-pill"
            accessibilityRole="button"
            accessibilityLabel={t('profile.signals.mutual_other', {
              count: mutualConnectionCount,
            })}
            onPress={() => setModalOpen(true)}
          >
            <Pill variant="default">
              {String.fromCodePoint(0x1f517)}{' '}
              {t('profile.signals.mutual', {
                count: mutualConnectionCount,
                defaultValue: t('profile.signals.mutual_other', {
                  count: mutualConnectionCount,
                }),
              })}
            </Pill>
          </Pressable>
        ) : null}

        {showRating ? (
          <View
            testID="profile-signals-rating-pill"
            accessibilityLabel={t('profile.signals.rating', {
              rating: avgMeetingRating.toFixed(1),
            })}
          >
            <Pill variant="default">
              {'★'} {avgMeetingRating.toFixed(1)}{' '}
              {t('profile.signals.reviews', {
                count: totalMeetingReviews,
                defaultValue: t('profile.signals.reviews_other', {
                  count: totalMeetingReviews,
                }),
              })}
            </Pill>
          </View>
        ) : null}
      </View>

      <MutualConnectionsModal
        visible={modalOpen}
        userIds={mutualTopUserIds}
        onClose={() => setModalOpen(false)}
      />
    </>
  );
}
