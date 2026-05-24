import { useState } from 'react';
import { View, Text, FlatList } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useWarmIntroSuggestions } from '~/features/intros/hooks/useWarmIntroSuggestions';
import { WarmIntroSuggestionCard } from '~/features/intros/components/WarmIntroSuggestionCard';
import {
  WarmIntroComposeSheet,
  type WarmIntroComposeTarget,
} from '~/features/intros/components/WarmIntroComposeSheet';
import type { WarmIntroSuggestion } from '~/features/intros/services/warmIntros.service';

type Props = {
  /** Override the suggestion limit (default 10). */
  limit?: number;
};

/**
 * Horizontal strip of warm-intro candidate cards. Mounted at the top
 * of the discovery feed. Returns null when there are no candidates,
 * so it never takes up vertical space on a brand-new account or for a
 * viewer who hasn't built a network yet.
 */
export function WarmIntroSuggestionsStrip({ limit }: Props) {
  const { t } = useTranslation();
  const query = useWarmIntroSuggestions(limit);
  const [composeTarget, setComposeTarget] = useState<WarmIntroComposeTarget | null>(null);

  const rows = query.data ?? [];
  if (rows.length === 0) return null;

  const onAsk = (s: WarmIntroSuggestion) => {
    setComposeTarget({
      mutualId: s.topMutualId,
      mutualName: s.topMutualName,
      mutualHandle: s.topMutualHandle,
      mutualPhotoUrl: null,
      targetId: s.targetId,
      targetName: s.targetName,
      targetHandle: s.targetHandle,
    });
  };

  return (
    <View testID="warm-intro-strip" className="mt-2">
      <Text className="font-display-bold text-body-md text-navy uppercase tracking-wide px-gutter mb-2">
        {t('intros.warm.stripTitle')}
      </Text>
      <FlatList
        horizontal
        showsHorizontalScrollIndicator={false}
        data={rows}
        keyExtractor={(item) => item.targetId}
        renderItem={({ item }) => (
          <WarmIntroSuggestionCard suggestion={item} onAsk={onAsk} />
        )}
        contentContainerStyle={{ paddingHorizontal: 12 }}
      />

      <WarmIntroComposeSheet
        visible={composeTarget !== null}
        context={composeTarget}
        onClose={() => setComposeTarget(null)}
        onSent={() => setComposeTarget(null)}
      />
    </View>
  );
}
