import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Card } from '~/components/ui/Card';
import { Pill } from '~/components/ui/Pill';
import { Avatar } from '~/components/ui/Avatar';
import type { OpportunityFeedItem } from '~/features/opportunities/services/opportunities.service';

type Props = {
  opportunity: OpportunityFeedItem;
  onPress?: (id: string) => void;
  onAuthorPress?: (authorHandle: string) => void;
  testID?: string;
};

/**
 * Per audit P2-6, the kind chip no longer drives a per-kind colour. A single
 * neutral navy pill carries the kind label; semantic chips (remote / closed)
 * stay on their semantic palette so they remain scannable as *status*.
 */
export function OpportunityCard({ opportunity, onPress, onAuthorPress, testID }: Props) {
  const { t } = useTranslation();
  const handlePress = () => onPress?.(opportunity.id);

  const locationLabel =
    [opportunity.locationCity, opportunity.locationCountry].filter(Boolean).join(', ') || null;

  const cardTestID = testID ?? `opportunity-card-${opportunity.id}`;

  return (
    <View className="mx-gutter mb-3">
      <Card testID={cardTestID} onPress={handlePress}>
        {/* Kind chip + remote indicator row */}
        <View className="flex-row items-center gap-2 mb-2 flex-wrap">
          <Pill variant="navy" testID={`${cardTestID}-kind`}>
            {t(`opportunities.kind.${opportunity.kind}`)}
          </Pill>
          {opportunity.remoteOk ? (
            <Pill variant="success" testID={`${cardTestID}-remote`}>
              {t('opportunities.filter.remoteOnly')}
            </Pill>
          ) : null}
          {locationLabel ? (
            <Text className="font-body text-body-sm text-muted">{locationLabel}</Text>
          ) : null}
        </View>

        {/* Title */}
        <Text
          testID={`${cardTestID}-title`}
          className="font-display-bold text-body-lg text-navy"
          numberOfLines={2}
        >
          {opportunity.title}
        </Text>

        {/* Body excerpt (3 lines) */}
        <Text
          testID={`${cardTestID}-body`}
          className="font-body text-body-md text-body mt-1"
          numberOfLines={3}
        >
          {opportunity.body}
        </Text>

        {/* Tags */}
        {opportunity.tags.length > 0 ? (
          <View className="flex-row gap-1.5 mt-2 flex-wrap">
            {opportunity.tags.map((tag) => (
              <Pill key={tag} variant="muted">
                #{tag}
              </Pill>
            ))}
          </View>
        ) : null}

        {/* Inline author row — borderless to avoid the cards-on-cards nesting
            the audit calls out in P2-13. */}
        <AuthorRow
          name={opportunity.authorName}
          handle={opportunity.authorHandle}
          primaryRole={opportunity.authorPrimaryRole}
          photoUrl={opportunity.authorPhotoUrl}
          onPress={onAuthorPress ? () => onAuthorPress(opportunity.authorHandle) : undefined}
          testID={`${cardTestID}-author`}
        />

        {/* Interested count */}
        {opportunity.interestedCount > 0 ? (
          <Text
            testID={`${cardTestID}-interested`}
            className="font-display-bold text-display-xs text-navy mt-2"
          >
            {t('opportunities.detail.viewInterested', { count: opportunity.interestedCount })}
          </Text>
        ) : null}
      </Card>
    </View>
  );
}

/**
 * Borderless author footer used inside an OpportunityCard / OpportunityDetail.
 * Lives alongside the card component because it's tightly coupled to the
 * opportunity layout (top divider, no own surface). Exporting so the detail
 * view can reuse the same row.
 */
export function AuthorRow({
  name,
  handle,
  primaryRole,
  photoUrl,
  onPress,
  testID,
}: {
  name: string;
  handle: string;
  primaryRole?: string | null;
  photoUrl?: string | null;
  onPress?: () => void;
  testID?: string;
}) {
  const meta = primaryRole ? `@${handle} · ${primaryRole}` : `@${handle}`;
  const rowClass =
    'flex-row items-center gap-2 mt-3 pt-3 border-t border-slate-100 active:opacity-70';
  const content = (
    <>
      <Avatar name={name} photoUrl={photoUrl} size={32} />
      <View className="flex-1">
        <Text className="font-display-bold text-display-sm text-navy" numberOfLines={1}>
          {name}
        </Text>
        <Text className="font-body text-body-sm text-muted" numberOfLines={1}>
          {meta}
        </Text>
      </View>
    </>
  );
  if (onPress) {
    return (
      <Pressable
        testID={testID}
        onPress={onPress}
        accessibilityRole="button"
        accessibilityLabel={name}
        className={rowClass}
      >
        {content}
      </Pressable>
    );
  }
  return (
    <View testID={testID} className={rowClass}>
      {content}
    </View>
  );
}
