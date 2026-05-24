import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Pill, type PillVariant } from '~/components/ui/Pill';
import { UserCard } from '~/components/ui/UserCard';
import type {
  OpportunityFeedItem,
  OpportunityKind,
} from '~/features/opportunities/services/opportunities.service';

/**
 * Per-kind colour palette so the feed scans by intent. Maps onto the
 * existing Pill variants — anything not enumerated here falls through
 * to 'default' (gold-pale on navy text).
 */
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
  opportunity: OpportunityFeedItem;
  onPress?: (id: string) => void;
  onAuthorPress?: (authorHandle: string) => void;
  testID?: string;
};

export function OpportunityCard({ opportunity, onPress, onAuthorPress, testID }: Props) {
  const { t } = useTranslation();
  const handlePress = () => onPress?.(opportunity.id);

  const locationLabel =
    [opportunity.locationCity, opportunity.locationCountry].filter(Boolean).join(', ') || null;

  const cardTestID = testID ?? `opportunity-card-${opportunity.id}`;

  return (
    <Pressable
      testID={cardTestID}
      onPress={handlePress}
      accessibilityRole="button"
      accessibilityLabel={opportunity.title}
      className="bg-white border border-border rounded-[14px] p-3 mx-3 mb-3"
    >
      {/* Kind chip + remote indicator row */}
      <View className="flex-row items-center gap-2 mb-2 flex-wrap">
        <Pill variant={KIND_VARIANT[opportunity.kind]} testID={`${cardTestID}-kind`}>
          {t(`opportunities.kind.${opportunity.kind}`)}
        </Pill>
        {opportunity.remoteOk ? (
          <Pill variant="success" testID={`${cardTestID}-remote`}>
            {t('opportunities.filter.remoteOnly')}
          </Pill>
        ) : null}
        {locationLabel ? (
          <Text className="font-body text-[11px] text-muted">{locationLabel}</Text>
        ) : null}
      </View>

      {/* Title */}
      <Text
        testID={`${cardTestID}-title`}
        className="font-display-bold text-[14px] text-navy"
        numberOfLines={2}
      >
        {opportunity.title}
      </Text>

      {/* Body excerpt (3 lines) */}
      <Text
        testID={`${cardTestID}-body`}
        className="font-body text-[12px] text-body mt-1"
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

      {/* Author card */}
      <View className="mt-3">
        <UserCard
          name={opportunity.authorName}
          handle={opportunity.authorHandle}
          primaryRole={opportunity.authorPrimaryRole ?? ''}
          photoUrl={opportunity.authorPhotoUrl}
          onPress={onAuthorPress ? () => onAuthorPress(opportunity.authorHandle) : undefined}
          testID={`${cardTestID}-author`}
        />
      </View>

      {/* Interested count */}
      {opportunity.interestedCount > 0 ? (
        <Text
          testID={`${cardTestID}-interested`}
          className="font-display-bold text-[11px] text-navy mt-2"
        >
          {t('opportunities.detail.viewInterested', { count: opportunity.interestedCount })}
        </Text>
      ) : null}
    </Pressable>
  );
}
