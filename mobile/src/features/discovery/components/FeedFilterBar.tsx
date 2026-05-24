import { View, Text, Pressable, ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Pill } from '~/components/ui/Pill';
import {
  useFeedFiltersStore,
  type GoalType,
  type RoleKind,
} from '~/features/discovery/store/feedFiltersStore';

const ROLE_OPTIONS: RoleKind[] = ['founder', 'leader', 'builder', 'investor'];
const GOAL_OPTIONS: GoalType[] = [
  'hire',
  'be_hired',
  'co_found',
  'invest',
  'take_investment',
  'advise',
  'find_advisor',
  'peer_connect',
];

export function FeedFilterBar() {
  const { t } = useTranslation();
  const roles = useFeedFiltersStore((s) => s.roles);
  const goalTypes = useFeedFiltersStore((s) => s.goalTypes);
  const country = useFeedFiltersStore((s) => s.country);
  const query = useFeedFiltersStore((s) => s.query);
  const toggleRole = useFeedFiltersStore((s) => s.toggleRole);
  const toggleGoalType = useFeedFiltersStore((s) => s.toggleGoalType);
  const clear = useFeedFiltersStore((s) => s.clear);

  const hasActiveFilters =
    roles.length > 0 || goalTypes.length > 0 || country.trim().length > 0 || query.trim().length > 0;

  return (
    <View testID="feed-filter-bar" className="px-6 pb-3">
      <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-1">
        {t('discovery.filter.role')}
      </Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ gap: 6, paddingRight: 8 }}
        className="mb-3"
      >
        {ROLE_OPTIONS.map((value) => {
          const active = roles.includes(value);
          return (
            <Pressable
              key={value}
              testID={`filter-role-${value}`}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => toggleRole(value)}
            >
              <Pill variant={active ? 'solid' : 'outline'}>{t(`discovery.roles.${value}`)}</Pill>
            </Pressable>
          );
        })}
      </ScrollView>

      <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-1">
        {t('discovery.filter.goal')}
      </Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={{ gap: 6, paddingRight: 8 }}
      >
        {GOAL_OPTIONS.map((value) => {
          const active = goalTypes.includes(value);
          return (
            <Pressable
              key={value}
              testID={`filter-goal-${value}`}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => toggleGoalType(value)}
            >
              <Pill variant={active ? 'solid' : 'outline'}>{t(`discovery.goals.${value}`)}</Pill>
            </Pressable>
          );
        })}
      </ScrollView>

      {hasActiveFilters ? (
        <View className="mt-3 flex-row">
          <Pressable
            testID="filter-clear"
            accessibilityRole="button"
            onPress={() => clear()}
          >
            <Pill variant="muted">{t('discovery.filter.clear')}</Pill>
          </Pressable>
        </View>
      ) : null}
    </View>
  );
}
