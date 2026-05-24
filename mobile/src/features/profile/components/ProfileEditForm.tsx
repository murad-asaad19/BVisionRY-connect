import { useCallback, useState } from 'react';
import { View, Text, ScrollView, Pressable, KeyboardAvoidingView, Platform } from 'react-native';
import { router } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { usePreventRemove, useNavigation } from '@react-navigation/native';
import { useTranslation } from 'react-i18next';
import { ChevronRight } from 'lucide-react-native';
import { useCurrentUserProfile } from '~/features/profile/hooks/useCurrentUserProfile';
import { useUpdateProfile } from '~/features/profile/hooks/useUpdateProfile';
import { checkHandleAvailable } from '~/features/profile/services/profile.service';
import { AvatarUploadButton } from '~/features/media/components/AvatarUploadButton';
import { GoalRefreshBanner } from '~/features/profile/components/GoalRefreshBanner';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { Pill } from '~/components/ui/Pill';
import { BottomSheet } from '~/components/ui/Modal';
import { TopBar } from '~/components/ui/TopBar';
import { SkeletonProfile } from '~/components/ui/Skeleton';
import { useConfirm } from '~/components/ui/ConfirmDialog';
import { colors } from '~/theme/colors';
import {
  NameSchema,
  HeadlineSchema,
  BioSchema,
  GoalTextSchema,
  CitySchema,
  CountrySchema,
  HandleSchema,
  GoalTypeSchema,
} from '~/features/profile/schemas';
import type { Database } from '~/lib/supabase/types.gen';

type RoleKind = Database['public']['Enums']['role_kind'];
type GoalType = Database['public']['Enums']['goal_type'];

const ROLE_OPTIONS: RoleKind[] = ['founder', 'leader', 'builder', 'investor'];
const GOAL_TYPE_OPTIONS: GoalType[] = [
  'hire',
  'be_hired',
  'co_found',
  'invest',
  'take_investment',
  'advise',
  'find_advisor',
  'peer_connect',
];

const HEADLINE_MAX = 120;
const BIO_MAX = 1000;
const GOAL_TEXT_MAX = 280;

type FormValues = {
  name: string;
  handle: string;
  headline: string;
  bio: string;
  goalText: string;
  goalType: GoalType;
  city: string;
  country: string;
  roles: RoleKind[];
  primaryRole: RoleKind | undefined;
};

export function ProfileEditForm() {
  const { t } = useTranslation();
  const { data: profile, isLoading } = useCurrentUserProfile();

  if (isLoading || !profile) {
    return (
      <View className="flex-1 bg-surface">
        <TopBar back title={t('profile.edit.title')} />
        <SkeletonProfile />
      </View>
    );
  }

  return <ProfileEditFormBody profile={profile} />;
}

function ProfileEditFormBody({
  profile,
}: {
  profile: NonNullable<ReturnType<typeof useCurrentUserProfile>['data']>;
}) {
  const { t } = useTranslation();
  const navigation = useNavigation();
  const confirm = useConfirm();
  const updateMutation = useUpdateProfile();
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [goalTypeSheetOpen, setGoalTypeSheetOpen] = useState(false);

  const {
    control,
    handleSubmit,
    watch,
    setValue,
    setError,
    formState: { errors, isDirty, isSubmitting },
    getValues,
  } = useForm<FormValues>({
    defaultValues: {
      name: profile.name ?? '',
      handle: profile.handle ?? '',
      headline: profile.headline ?? '',
      bio: profile.bio ?? '',
      goalText: profile.goal_text ?? '',
      goalType: (profile.goal_type as GoalType | null) ?? 'peer_connect',
      city: profile.city ?? '',
      country: profile.country ?? '',
      roles: (profile.roles as RoleKind[] | null) ?? [],
      primaryRole: (profile.primary_role as RoleKind | null) ?? undefined,
    },
  });

  // Watching these keeps the dependent UI in sync (counter, role chips,
  // primary-role chip-group, goal-type label). react-hook-form re-renders the
  // form on every watch update — acceptable for a single-screen form.
  const headline = watch('headline');
  const roles = watch('roles');
  const primaryRole = watch('primaryRole');
  const goalType = watch('goalType');

  // P0-3: branded ConfirmDialog instead of native Alert. usePreventRemove
  // intercepts both the hardware back button and any router navigation, then
  // calls `navigation.dispatch(data.action)` only when the user confirms.
  const confirmDiscard = useCallback(
    async (proceed: () => void) => {
      const ok = await confirm({
        title: t('profile.confirmDiscard.title'),
        body: t('profile.confirmDiscard.body'),
        confirmLabel: t('profile.confirmDiscard.discard'),
        cancelLabel: t('profile.confirmDiscard.keepEditing'),
        destructive: true,
      });
      if (ok) proceed();
    },
    [confirm, t]
  );

  // Don't guard while submitting — the mutation succeeds, we navigate back,
  // and we don't want to re-prompt the user mid-save.
  usePreventRemove(isDirty && !isSubmitting, ({ data }) => {
    // Re-emit the original navigation action so the user lands where they
    // intended (Back vs. swipe-down vs. tab change all hit the same hook).
    void confirmDiscard(() => navigation.dispatch(data.action));
  });

  const toggleRole = (r: RoleKind) => {
    const current = getValues('roles');
    const next = current.includes(r) ? current.filter((x) => x !== r) : [...current, r];
    setValue('roles', next, { shouldDirty: true });
    const currentPrimary = getValues('primaryRole');
    if (currentPrimary && !next.includes(currentPrimary)) {
      setValue('primaryRole', next[0], { shouldDirty: true });
    }
    if (!currentPrimary && next.length === 1) {
      setValue('primaryRole', next[0], { shouldDirty: true });
    }
  };

  const onSave = async (values: FormValues) => {
    setSubmitError(null);

    // Schema gate — surface field-level errors via setError so users see them
    // inline rather than as a single string at the top. The schemas have
    // heterogeneous output types (HeadlineSchema/BioSchema return optional
    // string), so we narrow each check inline rather than try to build a
    // homogeneous array.
    const checks: Array<{
      field: keyof FormValues;
      result: { success: boolean; error?: { issues: { message?: string }[] } };
    }> = [
      { field: 'name', result: NameSchema.safeParse(values.name) },
      { field: 'handle', result: HandleSchema.safeParse(values.handle) },
      { field: 'headline', result: HeadlineSchema.safeParse(values.headline) },
      { field: 'bio', result: BioSchema.safeParse(values.bio) },
      { field: 'goalText', result: GoalTextSchema.safeParse(values.goalText) },
      { field: 'goalType', result: GoalTypeSchema.safeParse(values.goalType) },
      { field: 'city', result: CitySchema.safeParse(values.city) },
      { field: 'country', result: CountrySchema.safeParse(values.country) },
    ];
    let hadSchemaError = false;
    for (const c of checks) {
      if (!c.result.success) {
        const msg = c.result.error?.issues[0]?.message ?? t('profile.edit.validationFailed');
        setError(c.field, { message: msg });
        hadSchemaError = true;
      }
    }
    if (hadSchemaError) return;

    if (values.roles.length === 0) {
      setError('roles', { message: t('profile.edit.pickAtLeastOneRole') });
      return;
    }

    // Pre-flight: only check the handle when it actually changed. The RPC
    // performs a profile-table lookup; skipping it on no-op edits avoids a
    // round trip and a confusing "taken" error if the user owns the handle.
    const newHandle = values.handle.trim().toLowerCase();
    const oldHandle = profile.handle?.toLowerCase() ?? null;
    if (newHandle !== oldHandle) {
      try {
        const available = await checkHandleAvailable(newHandle);
        if (!available) {
          setError('handle', { message: t('profile.handleTaken') });
          return;
        }
      } catch (e) {
        setError('handle', {
          message: e instanceof Error ? e.message : t('profile.edit.validationFailed'),
        });
        return;
      }
    }

    const effectivePrimary =
      values.primaryRole && values.roles.includes(values.primaryRole)
        ? values.primaryRole
        : values.roles[0]!;

    try {
      await updateMutation.mutateAsync({
        name: values.name.trim(),
        handle: newHandle,
        headline: values.headline.trim() || null,
        bio: values.bio.trim() || null,
        goal_text: values.goalText.trim(),
        goal_type: values.goalType,
        city: values.city.trim(),
        country: values.country.trim(),
        roles: values.roles,
        primary_role: effectivePrimary,
      });
      router.back();
    } catch (e) {
      setSubmitError(e instanceof Error ? e.message : t('profile.edit.saveFailed'));
    }
  };

  return (
    <KeyboardAvoidingView
      // P1-15: lift the form (multiline bio + goal) above the keyboard on iOS.
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={{ flex: 1 }}
    >
      <View className="flex-1 bg-surface">
        {/* P2-4: standard TopBar with back chevron replaces the floating pt-16 title. */}
        <TopBar back title={t('profile.edit.title')} />
        <ScrollView className="flex-1" keyboardShouldPersistTaps="handled">
          <View className="px-gutter pt-4 pb-8">
            <GoalRefreshBanner goalUpdatedAt={profile.goal_updated_at ?? null} />

            <View className="items-center mb-2">
              <AvatarUploadButton currentPhotoUrl={profile.photo_url ?? null} />
              <Text className="font-body text-body-sm text-muted -mt-2 mb-2">
                {t('profile.edit.tapPhoto')}
              </Text>
            </View>

            <View className="gap-1">
              <Controller
                control={control}
                name="name"
                render={({ field: { onChange, value, onBlur } }) => (
                  <Input
                    testID="edit-name"
                    label={t('profile.edit.name')}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    errorText={errors.name?.message}
                  />
                )}
              />

              <Controller
                control={control}
                name="handle"
                render={({ field: { onChange, value, onBlur } }) => (
                  <Input
                    testID="edit-handle"
                    label={t('profile.edit.handle')}
                    value={value}
                    onChangeText={(s) => onChange(s.toLowerCase())}
                    onBlur={onBlur}
                    autoCapitalize="none"
                    placeholder="ahmad"
                    errorText={errors.handle?.message}
                  />
                )}
              />
              <Text className="font-body text-body-xs text-muted leading-snug mb-2">
                {t('profile.edit.handleHint')}
              </Text>

              <View className="flex-row items-end justify-between mb-1">
                <Text className="font-display-semibold text-display-xs text-muted uppercase tracking-wide">
                  {t('profile.edit.headlineLabel')}
                </Text>
                <Text testID="edit-headline-counter" className="font-body text-body-xs text-muted">
                  {headline.length} / {HEADLINE_MAX}
                </Text>
              </View>
              <Controller
                control={control}
                name="headline"
                render={({ field: { onChange, value, onBlur } }) => (
                  <Input
                    testID="edit-headline"
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    maxLength={HEADLINE_MAX}
                    errorText={errors.headline?.message}
                  />
                )}
              />

              <Controller
                control={control}
                name="bio"
                render={({ field: { onChange, value, onBlur } }) => (
                  <Input
                    testID="edit-bio"
                    label={t('profile.edit.bioLabel')}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    multiline
                    numberOfLines={4}
                    maxLength={BIO_MAX}
                    errorText={errors.bio?.message}
                  />
                )}
              />

              <Controller
                control={control}
                name="goalText"
                render={({ field: { onChange, value, onBlur } }) => (
                  <Input
                    testID="edit-goal-text"
                    label={t('profile.edit.goalTextLabel')}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    multiline
                    numberOfLines={3}
                    maxLength={GOAL_TEXT_MAX}
                    errorText={errors.goalText?.message}
                  />
                )}
              />

              <Text className="font-display-semibold text-display-xs text-muted uppercase tracking-wide mt-2 mb-1.5">
                {t('profile.edit.goalTypeLabel')}
              </Text>
              <Pressable
                testID="edit-goal-type-trigger"
                onPress={() => setGoalTypeSheetOpen(true)}
                accessibilityRole="button"
                accessibilityLabel={t('profile.edit.goalTypePick')}
                className="bg-white border-[1.5px] border-border rounded-[10px] px-3 py-3 mb-2 flex-row items-center justify-between"
              >
                <Text className="font-body text-body-md text-body" testID="edit-goal-type-value">
                  {t(`discovery.goals.${goalType}`)}
                </Text>
                {/* P0-1: lucide chevron replaces the `›` text glyph. */}
                <ChevronRight size={16} color={colors.muted} />
              </Pressable>
              {errors.goalType?.message ? (
                <Text className="font-body text-body-xs text-danger-text mt-1">
                  {errors.goalType.message}
                </Text>
              ) : null}

              <Controller
                control={control}
                name="city"
                render={({ field: { onChange, value, onBlur } }) => (
                  <Input
                    testID="edit-city"
                    label={t('profile.edit.city')}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    errorText={errors.city?.message}
                  />
                )}
              />
              <Controller
                control={control}
                name="country"
                render={({ field: { onChange, value, onBlur } }) => (
                  <Input
                    testID="edit-country"
                    label={t('profile.edit.country')}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    errorText={errors.country?.message}
                  />
                )}
              />

              <Text className="font-display-semibold text-display-xs text-muted uppercase tracking-wide mt-2 mb-1.5">
                {t('profile.edit.roles')}
              </Text>
              <View className="flex-row flex-wrap gap-2 mb-1">
                {ROLE_OPTIONS.map((r) => {
                  const selected = roles.includes(r);
                  return (
                    <Pressable
                      key={r}
                      testID={`edit-role-${r}`}
                      onPress={() => toggleRole(r)}
                      accessibilityRole="button"
                      accessibilityState={{ selected }}
                    >
                      <Pill variant={selected ? 'solid' : 'outline'}>
                        {t(`discovery.roles.${r}`)}
                        {selected ? ' ✓' : ''}
                      </Pill>
                    </Pressable>
                  );
                })}
              </View>
              {errors.roles?.message ? (
                <Text className="font-body text-body-xs text-danger-text mt-1">
                  {errors.roles.message}
                </Text>
              ) : null}
              {roles.length > 1 ? (
                <View className="mb-2">
                  <Text className="font-display-semibold text-display-xs text-muted uppercase tracking-wide mt-2 mb-1.5">
                    {t('profile.edit.primaryRole')}
                  </Text>
                  <View className="flex-row flex-wrap gap-2">
                    {roles.map((r) => (
                      <Pressable
                        key={r}
                        testID={`edit-primary-${r}`}
                        onPress={() => setValue('primaryRole', r, { shouldDirty: true })}
                        accessibilityRole="button"
                        accessibilityState={{ selected: primaryRole === r }}
                      >
                        <Pill variant={primaryRole === r ? 'solid' : 'outline'}>
                          {t(`discovery.roles.${r}`)}
                        </Pill>
                      </Pressable>
                    ))}
                  </View>
                </View>
              ) : null}

              {submitError && (
                <Text testID="edit-error" className="text-danger-text font-body mt-2">
                  {submitError}
                </Text>
              )}

              <View className="flex-row gap-3 mt-4">
                <View className="flex-1">
                  <Button
                    testID="edit-cancel"
                    variant="outline"
                    // `usePreventRemove` intercepts and shows the discard prompt
                    // when the form is dirty — Cancel just dispatches `back()`.
                    onPress={() => router.back()}
                  >
                    {t('profile.edit.cancel')}
                  </Button>
                </View>
                <View className="flex-1">
                  <Button
                    testID="edit-save"
                    variant="primary"
                    onPress={handleSubmit(onSave)}
                    loading={updateMutation.isPending || isSubmitting}
                  >
                    {t('profile.edit.save')}
                  </Button>
                </View>
              </View>
            </View>
          </View>
        </ScrollView>

        <BottomSheet
          visible={goalTypeSheetOpen}
          onClose={() => setGoalTypeSheetOpen(false)}
          testID="edit-goal-type-sheet"
        >
          <Text className="font-display-bold text-display-md text-navy mb-3 px-2">
            {t('profile.edit.goalTypePick')}
          </Text>
          <View className="flex-row flex-wrap gap-2 px-2 pb-2">
            {GOAL_TYPE_OPTIONS.map((option) => {
              const selected = option === goalType;
              return (
                <Pressable
                  key={option}
                  testID={`edit-goal-type-${option}`}
                  onPress={() => {
                    setValue('goalType', option, { shouldDirty: true, shouldValidate: true });
                    setGoalTypeSheetOpen(false);
                  }}
                  accessibilityRole="button"
                  accessibilityState={{ selected }}
                >
                  <Pill variant={selected ? 'solid' : 'outline'}>
                    {t(`discovery.goals.${option}`)}
                  </Pill>
                </Pressable>
              );
            })}
          </View>
        </BottomSheet>
      </View>
    </KeyboardAvoidingView>
  );
}
