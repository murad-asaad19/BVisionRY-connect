import { View, Text, ScrollView, TextInput, Switch } from 'react-native';
import { useTranslation } from 'react-i18next';
import { colors } from '~/theme/colors';
import { FilterChip } from '~/components/ui/FilterChip';
import type { OpportunityKind } from '~/features/opportunities/services/opportunities.service';

const ALL_KINDS: OpportunityKind[] = [
  'hiring',
  'seeking_role',
  'fundraising',
  'investing',
  'cofounder',
  'advising',
  'seeking_advisor',
  'collaboration',
];

export type OpportunityFilters = {
  kinds: OpportunityKind[];
  remoteOnly: boolean;
  search: string;
};

type Props = {
  value: OpportunityFilters;
  onChange: (filters: OpportunityFilters) => void;
  testID?: string;
};

export function OpportunityFilterBar({ value, onChange, testID }: Props) {
  const { t } = useTranslation();
  const baseTestID = testID ?? 'opportunity-filter-bar';

  const toggleKind = (kind: OpportunityKind) => {
    const set = new Set(value.kinds);
    if (set.has(kind)) set.delete(kind);
    else set.add(kind);
    onChange({ ...value, kinds: Array.from(set) });
  };

  return (
    <View testID={baseTestID} className="px-gutter pt-2 pb-1 bg-white border-b border-border">
      {/* Search input */}
      <TextInput
        testID={`${baseTestID}-search`}
        value={value.search}
        onChangeText={(s) => onChange({ ...value, search: s })}
        placeholder={t('opportunities.filter.searchPlaceholder')}
        placeholderTextColor={colors.muted}
        autoCapitalize="none"
        autoCorrect={false}
        accessibilityLabel={t('opportunities.filter.searchPlaceholder')}
        className="bg-surface border border-border rounded-[10px] px-3 py-2 text-body-md text-body font-body mb-2"
      />

      {/* Remote-only toggle */}
      <View className="flex-row items-center justify-between mb-2">
        <Text className="font-body text-body-md text-body">
          {t('opportunities.filter.remoteOnly')}
        </Text>
        <Switch
          testID={`${baseTestID}-remote`}
          value={value.remoteOnly}
          onValueChange={(v) => onChange({ ...value, remoteOnly: v })}
          accessibilityLabel={t('opportunities.filter.remoteOnly')}
        />
      </View>

      {/* Horizontal kind chips */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View className="flex-row gap-2 pb-1">
          {ALL_KINDS.map((kind) => {
            const active = value.kinds.includes(kind);
            return (
              <FilterChip
                key={kind}
                testID={`${baseTestID}-kind-${kind}`}
                active={active}
                onPress={() => toggleKind(kind)}
                label={t(`opportunities.kind.${kind}`)}
              />
            );
          })}
        </View>
      </ScrollView>
    </View>
  );
}
