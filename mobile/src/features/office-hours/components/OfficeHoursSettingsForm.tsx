import { useEffect, useMemo, useState } from 'react';
import { View, Text, Switch, ScrollView, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { Banner } from '~/components/ui/Banner';
import { QueryState } from '~/components/ui/QueryState';
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
  const [error, setError] = useState<string | null>(null);
  const [savedBanner, setSavedBanner] = useState(false);
  const update = useUpdateOfficeHoursSettings();

  useEffect(() => {
    if (savedBanner) {
      const id = setTimeout(() => setSavedBanner(false), 2500);
      return () => clearTimeout(id);
    }
    return undefined;
  }, [savedBanner]);

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setState((s) => ({ ...s, [key]: value }));
    setError(null);
  };

  const onSubmit = async () => {
    setError(null);
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
      setError(parsed.error.issues[0]?.message ?? 'invalid');
      return;
    }
    try {
      await update.mutateAsync(parsed.data);
      setSavedBanner(true);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'failed');
    }
  };

  return (
    <ScrollView
      testID="office-hours-settings-form"
      className="flex-1 bg-surface"
      contentContainerStyle={{ padding: 16, paddingBottom: 64 }}
    >
      {/* Enable toggle */}
      <View className="bg-white border border-border rounded-[10px] p-3 mb-4">
        <View className="flex-row items-center justify-between">
          <View className="flex-1 pr-3">
            <Text className="font-display-bold text-[13px] text-navy">
              {t('officeHours.settings.enableLabel')}
            </Text>
            <Text className="font-body text-[11px] text-muted mt-0.5">
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
      <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-1">
        {t('officeHours.settings.slotDuration')}
      </Text>
      <View className="flex-row gap-2 mb-4">
        {DURATIONS.map((d) => {
          const active = state.slotDurationMinutes === d;
          return (
            <Pressable
              key={d}
              testID={`office-hours-duration-${d}`}
              accessibilityRole="radio"
              accessibilityState={{ selected: active }}
              onPress={() => set('slotDurationMinutes', d)}
              className={`flex-1 px-3 py-2 rounded-[10px] border ${active ? 'border-navy bg-navy' : 'border-border bg-white'}`}
            >
              <Text
                className={`font-display-bold text-[12px] text-center ${active ? 'text-white' : 'text-navy'}`}
              >
                {d}m
              </Text>
            </Pressable>
          );
        })}
      </View>

      {/* Numeric inputs */}
      <Input
        testID="office-hours-max-bookings"
        label={t('officeHours.settings.maxBookingsPerWeek')}
        value={String(state.maxBookingsPerWeek)}
        onChangeText={(s) => {
          const n = parseInt(s.replace(/\D/g, ''), 10);
          if (!Number.isNaN(n)) set('maxBookingsPerWeek', Math.max(1, Math.min(50, n)));
        }}
        keyboardType="number-pad"
      />
      <Input
        testID="office-hours-buffer"
        label={t('officeHours.settings.bufferMinutes')}
        value={String(state.bufferMinutes)}
        onChangeText={(s) => {
          const n = parseInt(s.replace(/\D/g, ''), 10);
          if (!Number.isNaN(n)) set('bufferMinutes', Math.max(0, Math.min(60, n)));
        }}
        keyboardType="number-pad"
      />

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
      <Text className="font-body text-[10px] text-muted mb-3">
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
      <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-2 mt-2">
        {t('officeHours.settings.windowsTitle')}
      </Text>
      <WeeklyAvailabilityEditor
        windows={state.windows}
        defaultTimezone={tz}
        onChange={(next) => set('windows', next)}
        testID="office-hours-windows"
      />

      {error ? (
        <View className="mt-3">
          <Banner variant="warning" testID="office-hours-form-error">
            {error}
          </Banner>
        </View>
      ) : null}

      {savedBanner ? (
        <View className="mt-3">
          <Banner variant="success" testID="office-hours-saved-banner">
            {t('officeHours.settings.saved')}
          </Banner>
        </View>
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
  );
}
