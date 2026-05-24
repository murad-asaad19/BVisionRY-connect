import { View, Text, Pressable, ScrollView } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useTranslation } from 'react-i18next';
import { FilterChip } from '~/components/ui/FilterChip';
import { Pill } from '~/components/ui/Pill';
import { colors } from '~/theme/colors';
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

/**
 * Right-edge fade overlay over a horizontal chip ScrollView so users see
 * a visual affordance that more chips are off-screen (audit P1-10). The
 * gradient bleeds the parent's surface bg into the chip row so the chip
 * underneath doesn't suddenly clip; pointerEvents:none keeps taps live.
 */
function ScrollFade() {
  return (
    <LinearGradient
      colors={['transparent', colors.bg]}
      start={{ x: 0, y: 0.5 }}
      end={{ x: 1, y: 0.5 }}
      style={{
        position: 'absolute',
        right: 0,
        top: 0,
        bottom: 0,
        width: 24,
      }}
      pointerEvents="none"
    />
  );
}

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
    <View testID="feed-filter-bar" className="px-gutter pb-3">
      <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-1">
        {t('discovery.filter.role')}
      </Text>
      <View className="relative">
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 6, paddingRight: 28 }}
          className="mb-3"
        >
          {ROLE_OPTIONS.map((value) => {
            const active = roles.includes(value);
            return (
              <FilterChip
                key={value}
                testID={`filter-role-${value}`}
                active={active}
                onPress={() => toggleRole(value)}
                label={t(`discovery.roles.${value}`)}
              />
            );
          })}
        </ScrollView>
        <ScrollFade />
      </View>

      <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-1">
        {t('discovery.filter.goal')}
      </Text>
      <View className="relative">
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 6, paddingRight: 28 }}
        >
          {GOAL_OPTIONS.map((value) => {
            const active = goalTypes.includes(value);
            return (
              <FilterChip
                key={value}
                testID={`filter-goal-${value}`}
                active={active}
                onPress={() => toggleGoalType(value)}
                label={t(`discovery.goals.${value}`)}
              />
            );
          })}
        </ScrollView>
        <ScrollFade />
      </View>

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
