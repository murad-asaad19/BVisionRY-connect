import { View, Text, Pressable, ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Pill } from '~/components/ui/Pill';
import {
  useFeedFiltersStore,
  type GoalType,
  type RoleKind,
} from '~/features/discovery/store/feedFiltersStore';

const ROLE_OPTIONS: { value: RoleKind; label: string }[] = [
  { value: 'founder', label: 'Founder' },
  { value: 'leader', label: 'Leader' },
  { value: 'builder', label: 'Builder' },
  { value: 'investor', label: 'Investor' },
];

const GOAL_OPTIONS: { value: GoalType; label: string }[] = [
  { value: 'hire', label: 'Hire' },
  { value: 'be_hired', label: 'Be hired' },
  { value: 'co_found', label: 'Co-found' },
  { value: 'invest', label: 'Invest' },
  { value: 'take_investment', label: 'Take investment' },
  { value: 'advise', label: 'Advise' },
  { value: 'find_advisor', label: 'Find advisor' },
  { value: 'peer_connect', label: 'Peer connect' },
];

export function FeedFilterBar() {
  const { t } = useTranslation();
  const roles = useFeedFiltersStore((s) => s.roles);
  const goalTypes = useFeedFiltersStore((s) => s.goalTypes);
  const toggleRole = useFeedFiltersStore((s) => s.toggleRole);
  const toggleGoalType = useFeedFiltersStore((s) => s.toggleGoalType);

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
        {ROLE_OPTIONS.map((o) => {
          const active = roles.includes(o.value);
          return (
            <Pressable
              key={o.value}
              testID={`filter-role-${o.value}`}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => toggleRole(o.value)}
            >
              <Pill variant={active ? 'solid' : 'outline'}>{o.label}</Pill>
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
        {GOAL_OPTIONS.map((o) => {
          const active = goalTypes.includes(o.value);
          return (
            <Pressable
              key={o.value}
              testID={`filter-goal-${o.value}`}
              accessibilityRole="button"
              accessibilityState={{ selected: active }}
              onPress={() => toggleGoalType(o.value)}
            >
              <Pill variant={active ? 'solid' : 'outline'}>{o.label}</Pill>
            </Pressable>
          );
        })}
      </ScrollView>
    </View>
  );
}
