import { Platform, TextInput, View, Text, Pressable } from 'react-native';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import DateTimePicker, { type DateTimePickerEvent } from '@react-native-community/datetimepicker';
import { colors } from '~/theme/colors';

type Props = {
  value: string;
  onChange: (iso: string) => void;
  testID?: string;
  label?: string;
};

/** Resolve the viewer's IANA timezone with a safe fallback for older runtimes. */
function resolveLocalTz(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
  } catch {
    return 'UTC';
  }
}

export function DateTimeField(props: Props) {
  if (Platform.OS === 'web') return <WebDateTimeField {...props} />;
  return <NativeDateTimeField {...props} />;
}

function WebDateTimeField({ value, onChange, testID, label }: Props) {
  const { t } = useTranslation();
  const tz = resolveLocalTz();
  const webProps = { type: 'datetime-local' } as unknown as object;
  return (
    <View className="mb-3">
      {label && (
        <Text className="font-body text-body-md text-muted mb-1">{label}</Text>
      )}
      <TextInput
        testID={testID}
        value={isoToInputValue(value)}
        onChangeText={(text) => onChange(inputValueToIso(text))}
        placeholder="YYYY-MM-DDTHH:mm"
        placeholderTextColor={colors.muted}
        className="bg-white text-body px-card-lg py-3 rounded-lg border border-border font-body text-body-lg"
        {...webProps}
      />
      <Text className="font-body text-body-xs text-muted mt-1">
        {t('meetings.inputTimeZoneHint', { tz })}
      </Text>
    </View>
  );
}

function NativeDateTimeField({ value, onChange, testID, label }: Props) {
  const { t } = useTranslation();
  const tz = resolveLocalTz();
  const [showDate, setShowDate] = useState(false);
  const [showTime, setShowTime] = useState(false);

  const current = value ? new Date(value) : new Date();

  const merge = (date: Date | undefined, time: Date | undefined) => {
    const base = value ? new Date(value) : new Date();
    if (date) {
      base.setFullYear(date.getFullYear(), date.getMonth(), date.getDate());
    }
    if (time) {
      base.setHours(time.getHours(), time.getMinutes(), 0, 0);
    }
    onChange(base.toISOString());
  };

  const onDate = (_event: DateTimePickerEvent, selected?: Date) => {
    setShowDate(false);
    if (!selected) return;
    merge(selected, undefined);
    if (Platform.OS === 'android') setShowTime(true);
  };

  const onTime = (_event: DateTimePickerEvent, selected?: Date) => {
    setShowTime(false);
    if (!selected) return;
    merge(undefined, selected);
  };

  return (
    <View className="mb-3">
      {label && (
        <Text className="font-body text-body-md text-muted mb-1">{label}</Text>
      )}
      <Pressable
        testID={testID}
        onPress={() => setShowDate(true)}
        className="bg-white px-card-lg py-3 rounded-lg border border-border"
      >
        <Text
          className={`font-body text-body-lg ${value ? 'text-body' : 'text-muted'}`}
        >
          {value ? formatHuman(current) : 'Pick date & time'}
        </Text>
      </Pressable>
      {showDate && (
        <DateTimePicker
          testID={testID ? `${testID}-date-picker` : undefined}
          value={current}
          mode="date"
          onChange={onDate}
        />
      )}
      {showTime && (
        <DateTimePicker
          testID={testID ? `${testID}-time-picker` : undefined}
          value={current}
          mode="time"
          onChange={onTime}
        />
      )}
      <Text className="font-body text-body-xs text-muted mt-1">
        {t('meetings.inputTimeZoneHint', { tz })}
      </Text>
    </View>
  );
}

function isoToInputValue(iso: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return iso;
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function inputValueToIso(input: string): string {
  if (!input) return '';
  const d = new Date(input);
  if (isNaN(d.getTime())) return input;
  return d.toISOString();
}

function formatHuman(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
