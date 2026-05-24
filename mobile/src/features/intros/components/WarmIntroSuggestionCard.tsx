import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { Pill } from '~/components/ui/Pill';
import type { WarmIntroSuggestion } from '~/features/intros/services/warmIntros.service';

type Props = {
  suggestion: WarmIntroSuggestion;
  onAsk: (suggestion: WarmIntroSuggestion) => void;
  testID?: string;
};

/** First name of a "First Last" string (falls back to the whole string). */
function firstName(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) return name;
  return trimmed.split(/\s+/)[0] ?? trimmed;
}

/**
 * Horizontal card for a warm-intro candidate: the target's avatar +
 * name + role, the via-mutual line, and a CTA opening the compose
 * sheet pre-targeted at this (target, mutual) pair.
 */
export function WarmIntroSuggestionCard({ suggestion, onAsk, testID }: Props) {
  const { t } = useTranslation();

  const viaLine =
    suggestion.mutualCount > 1
      ? t('intros.warm.via_other', {
          name: suggestion.topMutualName,
          extra: suggestion.mutualCount - 1,
        })
      : t('intros.warm.via_one', { name: suggestion.topMutualName });

  const askLabel = t('intros.warm.askCta', { firstName: firstName(suggestion.topMutualName) });

  return (
    <View
      testID={testID ?? `warm-intro-card-${suggestion.targetHandle}`}
      className="bg-white border border-border rounded-xl p-card w-[220px] mr-2"
    >
      <View className="flex-row items-start gap-2">
        <AvatarCircle
          name={suggestion.targetName}
          photoUrl={suggestion.targetPhotoUrl}
          size={48}
        />
        <View className="flex-1 min-w-0">
          <Text className="font-display-bold text-display-sm text-navy" numberOfLines={1}>
            {suggestion.targetName}
          </Text>
          <Text className="font-body text-body-sm text-muted" numberOfLines={1}>
            @{suggestion.targetHandle}
          </Text>
        </View>
      </View>

      {suggestion.targetPrimaryRole ? (
        <View className="mt-2">
          <Pill variant="outline">{t(`discovery.roles.${suggestion.targetPrimaryRole}`)}</Pill>
        </View>
      ) : null}

      <Text
        className="font-body text-body-sm text-body mt-2"
        numberOfLines={1}
        testID={`warm-intro-card-via-${suggestion.targetHandle}`}
      >
        {viaLine}
      </Text>

      <Pressable
        testID={`warm-intro-card-ask-${suggestion.targetHandle}`}
        accessibilityRole="button"
        accessibilityLabel={askLabel}
        onPress={() => onAsk(suggestion)}
        className="bg-navy rounded-lg px-3 py-2 mt-3 items-center active:opacity-80"
      >
        <Text className="font-display-bold text-body-md text-white">{askLabel}</Text>
      </Pressable>
    </View>
  );
}
