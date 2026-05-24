import { useMemo, useState } from 'react';
import { View, Text, Switch, ScrollView, KeyboardAvoidingView, Platform } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { QueryState } from '~/components/ui/QueryState';
import { SegmentedControl } from '~/components/ui/SegmentedControl';
import { Stepper } from '~/components/ui/Stepper';
import { useToast } from '~/components/ui/Toast';
import { useOfficeHoursSettings } from '~/features/office-hours/hooks/useOfficeHoursSettings';
import { useUpdateOfficeHoursSettings } from '~/features/office-hours/hooks/useUpdateOfficeHoursSettings';
import {
  OfficeHoursSettingsSchema,
  type OfficeHoursSettingsInput,
  type SlotDuration,
  type Window,
} from '~/features/office-hours/schemas';
import { WeeklyAvailabilityEditor } from '~/features/office-hours/components/WeeklyAvailabilityEditor';

const DURATIONS: SlotDuration[] = [15, 30, 45, 60];

function deviceTimezone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
  } catch {
    return 'UTC';
  }
}

type FormState = {
  enabled: boolean;
  windows: Window[];
  slotDurationMinutes: SlotDuration;
  maxBookingsPerWeek: number;
  bufferMinutes: number;
  meetingLinkTemplate: string;
  notesTemplate: string;
};

export function OfficeHoursSettingsForm() {
  const query = useOfficeHoursSettings();
  return (
    <QueryState query={query}>
      {(settings) => settings && <Inner initial={settings} />}
    </QueryState>
  );
}

function Inner({
  initial,
}: {
  initial: {
    enabled: boolean;
    windows: Window[];
    slotDurationMinutes: SlotDuration;
    maxBookingsPerWeek: number;
    bufferMinutes: number;
    meetingLinkTemplate: string | null;
    notesTemplate: string | null;
  };
}) {
  const { t } = useTranslation();
  const toast = useToast();
  const tz = useMemo(deviceTimezone, []);
  const [state, setState] = useState<FormState>({
    enabled: initial.enabled,
    windows: initial.windows,
    slotDurationMinutes: initial.slotDurationMinutes,
    maxBookingsPerWeek: initial.maxBookingsPerWeek,
    bufferMinutes: initial.bufferMinutes,
    meetingLinkTemplate: initial.meetingLinkTemplate ?? '',
    notesTemplate: initial.notesTemplate ?? '',
  });
  const [fieldError, setFieldError] = useState<string | null>(null);
  const update = useUpdateOfficeHoursSettings();

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setState((s) => ({ ...s, [key]: value }));
    setFieldError(null);
  };

  const onSubmit = async () => {
    setFieldError(null);
    const input: OfficeHoursSettingsInput = {
      enabled: state.enabled,
      windows: state.windows,
      slotDurationMinutes: state.slotDurationMinutes,
      maxBookingsPerWeek: state.maxBookingsPerWeek,
      bufferMinutes: state.bufferMinutes,
      meetingLinkTemplate: state.meetingLinkTemplate.trim() || undefined,
      notesTemplate: state.notesTemplate.trim() || undefined,
    };
    const parsed = OfficeHoursSettingsSchema.safeParse(input);
    if (!parsed.success) {
      // Inline validation errors still get a field-level hint AND a toast so the
      // user notices on long forms where the offending field is scrolled away.
      const message = parsed.error.issues[0]?.message ?? 'invalid';
      setFieldError(message);
      toast.error(message);
      return;
    }
    try {
      await update.mutateAsync(parsed.data);
      toast.success(t('officeHours.settings.saved'));
    } catch (e) {
      const message = e instanceof Error ? e.message : t('officeHours.settings.saveFailed');
      toast.error(message);
    }
  };

  const durationOptions = useMemo(
    () =>
      DURATIONS.map((d) => ({
        value: String(d),
        label: t('officeHours.settings.slotDurationOption', { minutes: d }),
        testID: `office-hours-duration-${d}`,
      })),
    [t]
  );

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={{ flex: 1 }}
    >
      <ScrollView
        testID="office-hours-settings-form"
        className="flex-1 bg-surface"
        contentContainerStyle={{ padding: 16, paddingBottom: 64 }}
        keyboardShouldPersistTaps="handled"
      >
        {/* Enable toggle */}
        <View className="bg-white border border-border rounded-[10px] p-card mb-4">
          <View className="flex-row items-center justify-between">
            <View className="flex-1 pr-3">
              <Text className="font-display-bold text-display-sm text-navy">
                {t('officeHours.settings.enableLabel')}
              </Text>
              <Text className="font-body text-body-sm text-muted mt-0.5">
                {t('officeHours.settings.enableHelp')}
              </Text>
            </View>
            <Switch
              testID="office-hours-enable"
              value={state.enabled}
              onValueChange={(v) => set('enabled', v)}
            />
          </View>
        </View>

        {/* Slot duration segmented control */}
        <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-1.5">
          {t('officeHours.settings.slotDuration')}
        </Text>
        <View className="mb-4">
          <SegmentedControl
            testID="office-hours-duration"
            options={durationOptions}
            value={String(state.slotDurationMinutes)}
            onChange={(v) => set('slotDurationMinutes', Number(v) as SlotDuration)}
          />
        </View>

        {/* Numeric steppers — replaces regex-filtered text inputs (P3-8). */}
        <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-1.5">
          {t('officeHours.settings.maxBookingsPerWeek')}
        </Text>
        <View className="mb-4">
          <Stepper
            testID="office-hours-max-bookings"
            value={state.maxBookingsPerWeek}
            onChange={(n) => set('maxBookingsPerWeek', n)}
            min={1}
            max={50}
            step={1}
          />
        </View>

        <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-1.5">
          {t('officeHours.settings.bufferMinutes')}
        </Text>
        <View className="mb-4">
          <Stepper
            testID="office-hours-buffer"
            value={state.bufferMinutes}
            onChange={(n) => set('bufferMinutes', n)}
            min={0}
            max={60}
            step={5}
          />
        </View>

        {/* Meeting link template */}
        <Input
          testID="office-hours-link-template"
          label={t('officeHours.settings.meetingLinkLabel')}
          value={state.meetingLinkTemplate}
          onChangeText={(s) => set('meetingLinkTemplate', s)}
          placeholder="https://meet.example.com/{slot_id}"
          autoCapitalize="none"
          autoCorrect={false}
        />
        <Text className="font-body text-body-xs text-muted mb-3">
          {t('officeHours.settings.meetingLinkHelp')}
        </Text>

        {/* Notes template */}
        <Input
          testID="office-hours-notes-template"
          label={t('officeHours.settings.notesLabel')}
          value={state.notesTemplate}
          onChangeText={(s) => set('notesTemplate', s)}
          multiline
          numberOfLines={3}
          maxLength={2000}
        />

        {/* Weekly availability */}
        <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-2 mt-2">
          {t('officeHours.settings.windowsTitle')}
        </Text>
        <WeeklyAvailabilityEditor
          windows={state.windows}
          defaultTimezone={tz}
          onChange={(next) => set('windows', next)}
          testID="office-hours-windows"
        />

        {fieldError ? (
          <Text
            testID="office-hours-form-error"
            className="font-body text-body-sm text-danger-text mt-3"
          >
            {fieldError}
          </Text>
        ) : null}

        <View className="mt-4">
          <Button
            testID="office-hours-save"
            variant="primary"
            onPress={onSubmit}
            loading={update.isPending}
          >
            {t('officeHours.settings.save')}
          </Button>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
