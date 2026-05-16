import { useState } from 'react';
import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { StepperLayout } from './StepperLayout';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { Pill } from '~/components/ui/Pill';
import { Button } from '~/components/ui/Button';
import type { Database } from '~/lib/supabase/types.gen';

type RoleKind = Database['public']['Enums']['role_kind'];
const ROLES: { value: RoleKind; label: string }[] = [
  { value: 'founder', label: 'Founder' },
  { value: 'leader', label: 'Leader' },
  { value: 'builder', label: 'Builder' },
  { value: 'investor', label: 'Investor' },
];

export function RolesStep() {
  const { draft, setField } = useOnboardingDraft();
  const [selected, setSelected] = useState<RoleKind[]>(draft.roles ?? []);
  const [primary, setPrimary] = useState<RoleKind | undefined>(draft.primary_role);
  const [error, setError] = useState<string | null>(null);

  const toggle = (role: RoleKind) => {
    setError(null);
    setSelected((prev) => {
      const next = prev.includes(role) ? prev.filter((r) => r !== role) : [...prev, role];
      if (next.length === 1) setPrimary(next[0]);
      else if (primary && !next.includes(primary)) setPrimary(undefined);
      return next;
    });
  };

  const onNext = () => {
    if (selected.length === 0) {
      setError('Select at least one role.');
      return;
    }
    if (selected.length > 1 && !primary) {
      setError('Pick which role best describes you.');
      return;
    }
    const primaryRole = selected.length === 1 ? selected[0]! : primary!;
    setField('roles', selected);
    setField('primary_role', primaryRole);
    router.push('/(onboarding)/about');
  };

  return (
    <StepperLayout currentIndex={2} title="What do you do?">
      <View>
        <View className="flex-row flex-wrap gap-2 mb-2">
          {ROLES.map((r) => {
            const isSelected = selected.includes(r.value);
            return (
              <Pressable
                key={r.value}
                testID={`role-${r.value}`}
                onPress={() => toggle(r.value)}
                accessibilityRole="button"
                accessibilityState={{ selected: isSelected }}
              >
                <Pill variant={isSelected ? 'solid' : 'outline'}>
                  {r.label}
                  {isSelected ? ' ✓' : ''}
                </Pill>
              </Pressable>
            );
          })}
        </View>

        {selected.length > 1 && (
          <View className="mt-4">
            <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-2">
              Which is your primary role?
            </Text>
            <View className="flex-row flex-wrap gap-2">
              {selected.map((r) => (
                <Pressable
                  key={r}
                  testID={`primary-${r}`}
                  onPress={() => setPrimary(r)}
                  accessibilityRole="button"
                  accessibilityState={{ selected: primary === r }}
                >
                  <Pill variant={primary === r ? 'solid' : 'outline'}>{r}</Pill>
                </Pressable>
              ))}
            </View>
          </View>
        )}

        {error && (
          <Text testID="roles-error" className="text-danger-text mt-2">
            {error}
          </Text>
        )}

        <View className="mt-6">
          <Button testID="roles-next" variant="primary" onPress={onNext}>
            Next
          </Button>
        </View>
      </View>
    </StepperLayout>
  );
}
