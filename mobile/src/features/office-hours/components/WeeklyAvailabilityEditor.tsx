import { useMemo, useState } from 'react';
import { View, Text, Pressable, TextInput } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Copy, Plus, Trash2 } from 'lucide-react-native';
import { BottomSheet } from '~/components/ui/Modal';
import { IconButton } from '~/components/ui/IconButton';
import { Button } from '~/components/ui/Button';
import { colors } from '~/theme/colors';
import { WEEKDAY_KEYS, type Window } from '~/features/office-hours/schemas';

type Props = {
  windows: Window[];
  defaultTimezone: string;
  onChange: (next: Window[]) => void;
  testID?: string;
};

const HOURS_RE = /^([0-1]?\d|2[0-3]):([0-5]\d)$/;
// Weekday indices (0=Sunday) that count as "weekdays" for the copy affordance.
const WEEKDAY_INDICES = [1, 2, 3, 4, 5];

function minutesToHHMM(m: number): string {
  const h = Math.floor(m / 60);
  const mm = m % 60;
  return `${h.toString().padStart(2, '0')}:${mm.toString().padStart(2, '0')}`;
}

function parseHHMM(s: string): number | null {
  const match = HOURS_RE.exec(s.trim());
  if (!match) return null;
  const h = parseInt(match[1] ?? '0', 10);
  const mm = parseInt(match[2] ?? '0', 10);
  return h * 60 + mm;
}

/**
 * Lets the host author a week's worth of availability windows. Each
 * weekday can host multiple windows; each window has start + end (HH:MM)
 * and a timezone (defaults to device TZ). Serializes back into the
 * JSON shape that `set_office_hours` expects.
 *
 * Validation note: end > start is enforced both inline (red text below
 * the field) and again at submit time via the OfficeHoursSettingsSchema.
 *
 * UX (audit P2-8): per-day rows that hold any windows expose a copy button
 * that opens a small sheet to apply that day's windows to weekdays or all
 * days. Common Calendly pattern — avoids re-entering the same hours 5x.
 */
export function WeeklyAvailabilityEditor({
  windows,
  defaultTimezone,
  onChange,
  testID,
}: Props) {
  const { t } = useTranslation();
  const [copySource, setCopySource] = useState<number | null>(null);

  const grouped = useMemo(() => {
    const byDay = new Map<number, { window: Window; index: number }[]>();
    windows.forEach((w, i) => {
      const list = byDay.get(w.weekday) ?? [];
      list.push({ window: w, index: i });
      byDay.set(w.weekday, list);
    });
    return byDay;
  }, [windows]);

  const addWindowFor = (weekday: number) => {
    onChange([
      ...windows,
      {
        weekday,
        startMinute: 9 * 60,
        endMinute: 10 * 60,
        timezone: defaultTimezone,
      },
    ]);
  };

  const removeWindow = (index: number) => {
    onChange(windows.filter((_, i) => i !== index));
  };

  const updateWindow = (index: number, patch: Partial<Window>) => {
    onChange(windows.map((w, i) => (i === index ? { ...w, ...patch } : w)));
  };

  const applyCopy = (sourceWeekday: number, targetWeekdays: number[]) => {
    const source = (grouped.get(sourceWeekday) ?? []).map((entry) => entry.window);
    if (source.length === 0) return;
    // Replace all windows on each target day with a clone of the source day's
    // windows. Keeps any other days intact.
    const next: Window[] = [];
    for (const w of windows) {
      if (w.weekday === sourceWeekday) {
        next.push(w);
        continue;
      }
      if (!targetWeekdays.includes(w.weekday)) {
        next.push(w);
      }
    }
    for (const target of targetWeekdays) {
      if (target === sourceWeekday) continue;
      for (const src of source) {
        next.push({ ...src, weekday: target });
      }
    }
    onChange(next);
    setCopySource(null);
  };

  return (
    <View testID={testID ?? 'weekly-availability-editor'}>
      {WEEKDAY_KEYS.map((dayKey, weekday) => {
        const dayWindows = grouped.get(weekday) ?? [];
        const canCopy = dayWindows.length > 0;
        return (
          <View
            key={dayKey}
            testID={`weekly-availability-day-${weekday}`}
            className="mb-3 border border-border rounded-[10px] p-card bg-white"
          >
            <View className="flex-row items-center justify-between mb-2">
              <Text className="font-display-bold text-display-sm text-navy">
                {t(`officeHours.settings.${dayKey}`)}
              </Text>
              <View className="flex-row items-center gap-1">
                {canCopy ? (
                  <IconButton
                    icon={Copy}
                    onPress={() => setCopySource(weekday)}
                    label={t('officeHours.settings.copyHours')}
                    size="sm"
                    variant="subtle"
                    testID={`weekly-availability-copy-${weekday}`}
                  />
                ) : null}
                <Pressable
                  testID={`weekly-availability-add-${weekday}`}
                  accessibilityRole="button"
                  accessibilityLabel={t('officeHours.settings.addWindow')}
                  onPress={() => addWindowFor(weekday)}
                  className="flex-row items-center gap-1 px-2.5 py-1.5 rounded-md bg-gold-pale"
                >
                  <Plus size={12} color={colors.navy} />
                  <Text className="font-display-bold text-body-xs text-navy">
                    {t('officeHours.settings.addWindow')}
                  </Text>
                </Pressable>
              </View>
            </View>

            {dayWindows.length === 0 ? (
              <Text className="font-body text-body-sm text-muted">—</Text>
            ) : null}

            {dayWindows.map(({ window: w, index }) => {
              const startStr = minutesToHHMM(w.startMinute);
              const endStr = minutesToHHMM(w.endMinute);
              const invalid = w.endMinute <= w.startMinute;
              return (
                <View
                  key={`${weekday}-${index}`}
                  testID={`weekly-availability-row-${index}`}
                  className="flex-row items-center gap-2 mb-2"
                >
                  <View className="flex-1">
                    <TextInput
                      testID={`weekly-availability-start-${index}`}
                      value={startStr}
                      onChangeText={(s) => {
                        const v = parseHHMM(s);
                        if (v !== null) updateWindow(index, { startMinute: v });
                      }}
                      placeholder="09:00"
                      keyboardType="numbers-and-punctuation"
                      autoCorrect={false}
                      className="bg-white border border-border rounded-md px-2 py-1.5 text-body-md text-body font-body"
                    />
                  </View>
                  <Text className="font-body text-body-md text-muted">→</Text>
                  <View className="flex-1">
                    <TextInput
                      testID={`weekly-availability-end-${index}`}
                      value={endStr}
                      onChangeText={(s) => {
                        const v = parseHHMM(s);
                        if (v !== null) updateWindow(index, { endMinute: v });
                      }}
                      placeholder="10:00"
                      keyboardType="numbers-and-punctuation"
                      autoCorrect={false}
                      className="bg-white border border-border rounded-md px-2 py-1.5 text-body-md text-body font-body"
                    />
                  </View>
                  <View className="flex-[2]">
                    <TextInput
                      testID={`weekly-availability-tz-${index}`}
                      value={w.timezone}
                      onChangeText={(s) => updateWindow(index, { timezone: s.trim() })}
                      placeholder={defaultTimezone}
                      autoCapitalize="none"
                      autoCorrect={false}
                      className="bg-white border border-border rounded-md px-2 py-1.5 text-body-md text-body font-body"
                    />
                  </View>
                  <IconButton
                    icon={Trash2}
                    onPress={() => removeWindow(index)}
                    label={t('officeHours.settings.removeWindow')}
                    size="sm"
                    variant="subtle"
                    testID={`weekly-availability-remove-${index}`}
                  />
                  {invalid ? (
                    <View className="basis-full">
                      <Text
                        testID={`weekly-availability-error-${index}`}
                        className="font-body text-body-xs text-danger-text"
                      >
                        {t('officeHours.settings.windowEndAfterStart')}
                      </Text>
                    </View>
                  ) : null}
                </View>
              );
            })}
          </View>
        );
      })}

      <BottomSheet
        visible={copySource !== null}
        onClose={() => setCopySource(null)}
        testID="weekly-availability-copy-sheet"
      >
        {copySource !== null ? (
          <View>
            <Text className="font-display-bold text-display-md text-navy mb-1">
              {t('officeHours.settings.copyHours')}
            </Text>
            <Text className="font-body text-body-md text-muted mb-4">
              {t(`officeHours.settings.${WEEKDAY_KEYS[copySource]}`)}
            </Text>
            <View className="gap-2">
              <Button
                testID="weekly-availability-copy-weekdays"
                variant="primary"
                onPress={() => applyCopy(copySource, WEEKDAY_INDICES)}
              >
                {t('officeHours.settings.copyToWeekdays')}
              </Button>
              <Button
                testID="weekly-availability-copy-all"
                variant="outline"
                onPress={() => applyCopy(copySource, [0, 1, 2, 3, 4, 5, 6])}
              >
                {t('officeHours.settings.copyToAll')}
              </Button>
            </View>
          </View>
        ) : null}
      </BottomSheet>
    </View>
  );
}
