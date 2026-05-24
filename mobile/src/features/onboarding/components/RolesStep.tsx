import { useState } from 'react';
import { View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';
import { useForm, useWatch } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { StepperLayout } from './StepperLayout';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';
import { Pill } from '~/components/ui/Pill';
import { Button } from '~/components/ui/Button';
import type { Database } from '~/lib/supabase/types.gen';

type RoleKind = Database['public']['Enums']['role_kind'];

type FormValues = {
  roles: RoleKind[];
  primary_role?: RoleKind;
};

const ROLE_VALUES: RoleKind[] = ['founder', 'leader', 'builder', 'investor'];

export function RolesStep() {
  const { t } = useTranslation();
  const { draft, setField } = useOnboardingDraft();
  const [error, setError] = useState<string | null>(null);

  const { control, handleSubmit, setValue } = useForm<FormValues>({
    defaultValues: { roles: draft.roles ?? [], primary_role: draft.primary_role },
  });

  // Subscribing via useWatch keeps the chip UI reactive without re-binding
  // Controllers — the chip pickers aren't bound inputs, they mutate the form
  // state imperatively through setValue.
  const selected = useWatch({ control, name: 'roles' });
  const primary = useWatch({ control, name: 'primary_role' });

  const toggle = (role: RoleKind) => {
    setError(null);
    const next = selected.includes(role)
      ? selected.filter((r) => r !== role)
      : [...selected, role];
    setValue('roles', next, { shouldDirty: true });
    if (next.length === 1) {
      setValue('primary_role', next[0], { shouldDirty: true });
    } else if (primary && !next.includes(primary)) {
      setValue('primary_role', undefined, { shouldDirty: true });
    }
  };

  const onSubmit = (values: FormValues) => {
    if (values.roles.length === 0) {
      setError(t('onboarding.roles.errorPickOne'));
      return;
    }
    if (values.roles.length > 1 && !values.primary_role) {
      setError(t('onboarding.roles.errorPickPrimary'));
      return;
    }
    const primaryRole =
      values.roles.length === 1 ? values.roles[0]! : values.primary_role!;
    setField('roles', values.roles);
    setField('primary_role', primaryRole);
    router.push('/(onboarding)/about');
  };

  return (
    <StepperLayout currentIndex={2} title={t('onboarding.roles.title')}>
      <View>
        <View className="flex-row flex-wrap gap-2 mb-2">
          {ROLE_VALUES.map((value) => {
            const isSelected = selected.includes(value);
            return (
              <Pressable
                key={value}
                testID={`role-${value}`}
                onPress={() => toggle(value)}
                accessibilityRole="button"
                accessibilityState={{ selected: isSelected }}
              >
                <Pill variant={isSelected ? 'solid' : 'outline'}>
                  {t(`onboarding.roles.${value}`)}
                  {isSelected ? ' ✓' : ''}
                </Pill>
              </Pressable>
            );
          })}
        </View>

        {selected.length > 1 && (
          <View className="mt-4">
            <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-2">
              {t('onboarding.roles.primaryQuestion')}
            </Text>
            <View className="flex-row flex-wrap gap-2">
              {selected.map((r) => (
                <Pressable
                  key={r}
                  testID={`primary-${r}`}
                  onPress={() => setValue('primary_role', r, { shouldDirty: true })}
                  accessibilityRole="button"
                  accessibilityState={{ selected: primary === r }}
                >
                  <Pill variant={primary === r ? 'solid' : 'outline'}>
                    {t(`onboarding.roles.${r}`)}
                  </Pill>
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
          <Button testID="roles-next" variant="primary" onPress={handleSubmit(onSubmit)}>
            {t('onboarding.roles.next')}
          </Button>
        </View>
      </View>
    </StepperLayout>
  );
}
