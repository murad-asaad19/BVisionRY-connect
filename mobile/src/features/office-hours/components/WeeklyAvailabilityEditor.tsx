import { useMemo } from 'react';
import { View, Text, Pressable, TextInput } from 'react-native';
import { useTranslation } from 'react-i18next';
import { WEEKDAY_KEYS, type Window } from '~/features/office-hours/schemas';

type Props = {
  windows: Window[];
  defaultTimezone: string;
  onChange: (next: Window[]) => void;
  testID?: string;
};

const HOURS_RE = /^([0-1]?\d|2[0-3]):([0-5]\d)$/;

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
 */
export function WeeklyAvailabilityEditor({
  windows,
  defaultTimezone,
  onChange,
  testID,
}: Props) {
  const { t } = useTranslation();

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

  return (
    <View testID={testID ?? 'weekly-availability-editor'}>
      {WEEKDAY_KEYS.map((dayKey, weekday) => {
        const dayWindows = grouped.get(weekday) ?? [];
        return (
          <View
            key={dayKey}
            testID={`weekly-availability-day-${weekday}`}
            className="mb-3 border border-border rounded-[10px] p-3 bg-white"
          >
            <View className="flex-row items-center justify-between mb-2">
              <Text className="font-display-bold text-[13px] text-navy">
                {t(`officeHours.settings.${dayKey}`)}
              </Text>
              <Pressable
                testID={`weekly-availability-add-${weekday}`}
                accessibilityRole="button"
                accessibilityLabel={t('officeHours.settings.addWindow')}
                onPress={() => addWindowFor(weekday)}
                className="px-2 py-1 rounded-md bg-gold-pale"
              >
                <Text className="font-display-bold text-[10px] text-navy">
                  + {t('officeHours.settings.addWindow')}
                </Text>
              </Pressable>
            </View>

            {dayWindows.length === 0 ? (
              <Text className="font-body text-[11px] text-muted">—</Text>
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
                      className="bg-white border border-border rounded-md px-2 py-1.5 text-[12px] text-body font-body"
                    />
                  </View>
                  <Text className="font-body text-[12px] text-muted">→</Text>
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
                      className="bg-white border border-border rounded-md px-2 py-1.5 text-[12px] text-body font-body"
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
                      className="bg-white border border-border rounded-md px-2 py-1.5 text-[12px] text-body font-body"
                    />
                  </View>
                  <Pressable
                    testID={`weekly-availability-remove-${index}`}
                    accessibilityRole="button"
                    accessibilityLabel={t('common.cancel')}
                    onPress={() => removeWindow(index)}
                    className="px-2 py-1 rounded-md bg-white border border-border"
                  >
                    <Text className="font-display-bold text-[12px] text-danger-text">×</Text>
                  </Pressable>
                  {invalid ? (
                    <View className="basis-full">
                      <Text
                        testID={`weekly-availability-error-${index}`}
                        className="font-body text-[10px] text-danger-text"
                      >
                        end must be after start
                      </Text>
                    </View>
                  ) : null}
                </View>
              );
            })}
          </View>
        );
      })}
    </View>
  );
}

