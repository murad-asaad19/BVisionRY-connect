import { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useProposeMeeting } from '~/features/meetings/hooks/useProposeMeeting';
import { SlotsSchema, DurationSchema, MeetingUrlSchema } from '~/features/meetings/schemas';
import { DateTimeField } from './DateTimeField';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { FilterChip } from '~/components/ui/FilterChip';
import { useToast } from '~/components/ui/Toast';

type Props = {
  visible: boolean;
  conversationId: string;
  onClose: () => void;
  onSent: () => void;
};

const DURATIONS = [15, 30, 45, 60, 90, 120];

export function ProposeMeetingSheet({ visible, conversationId, onClose, onSent }: Props) {
  const { t } = useTranslation();
  const toast = useToast();
  const [slot1, setSlot1] = useState('');
  const [slot2, setSlot2] = useState('');
  const [slot3, setSlot3] = useState('');
  const [duration, setDuration] = useState(30);
  const [url, setUrl] = useState('');
  const [error, setError] = useState<string | null>(null);
  const propose = useProposeMeeting(conversationId);

  const reset = () => {
    setSlot1('');
    setSlot2('');
    setSlot3('');
    setDuration(30);
    setUrl('');
    setError(null);
  };

  const onSubmit = async () => {
    setError(null);
    // Dedupe by normalised ISO instant so two slot fields holding the same
    // moment-of-time don't produce a duplicate entry server-side.
    const slotsRaw = [slot1, slot2, slot3].filter((s) => s.length > 0);
    const seen = new Set<string>();
    const slots: string[] = [];
    for (const s of slotsRaw) {
      const ts = Date.parse(s);
      const key = Number.isNaN(ts) ? s : new Date(ts).toISOString();
      if (seen.has(key)) continue;
      seen.add(key);
      slots.push(s);
    }
    const slotsParsed = SlotsSchema.safeParse(slots);
    if (!slotsParsed.success) {
      setError(t('meetings.propose.errors.slotsRange'));
      return;
    }
    const durationParsed = DurationSchema.safeParse(duration);
    if (!durationParsed.success) {
      setError(t('meetings.propose.errors.duration'));
      return;
    }
    const urlParsed = MeetingUrlSchema.safeParse(url);
    if (!urlParsed.success) {
      setError(t('meetings.propose.errors.url'));
      return;
    }

    const timezone = (() => {
      try {
        return Intl.DateTimeFormat().resolvedOptions().timeZone || null;
      } catch {
        return null;
      }
    })();

    try {
      await propose.mutateAsync({
        slots: slotsParsed.data,
        durationMinutes: durationParsed.data,
        meetingUrl: urlParsed.data ?? null,
        timezone,
      });
      toast.success(t('meetings.statusProposed'));
      reset();
      onSent();
    } catch (e) {
      setError(e instanceof Error ? e.message : t('meetings.propose.errors.submitFailed'));
    }
  };

  return (
    <BottomSheet visible={visible} onClose={onClose} testID="propose-meeting-sheet">
      <ScrollView keyboardShouldPersistTaps="handled">
        <Text className="font-display-bold text-display-md text-navy mb-1">
          {t('meetings.propose.title')}
        </Text>
        <Text className="font-body text-body-md text-muted mb-3">
          {t('meetings.propose.subtitle')}
        </Text>

        <DateTimeField
          value={slot1}
          onChange={setSlot1}
          testID="propose-slot-1"
          label={t('meetings.propose.slot1Label')}
        />
        <DateTimeField
          value={slot2}
          onChange={setSlot2}
          testID="propose-slot-2"
          label={t('meetings.propose.slot2Label')}
        />
        <DateTimeField
          value={slot3}
          onChange={setSlot3}
          testID="propose-slot-3"
          label={t('meetings.propose.slot3Label')}
        />

        <Text className="font-display-semibold text-body-xs text-muted uppercase tracking-wide mb-1.5 mt-1">
          {t('meetings.propose.durationLabel')}
        </Text>
        <View className="flex-row flex-wrap gap-2 mb-3">
          {DURATIONS.map((d) => (
            <FilterChip
              key={d}
              testID={`propose-duration-${d}`}
              active={duration === d}
              onPress={() => setDuration(d)}
              label={t('meetings.propose.durationOption', { minutes: d })}
            />
          ))}
        </View>

        <Input
          testID="propose-url"
          label={t('meetings.propose.urlLabel')}
          value={url}
          onChangeText={setUrl}
          placeholder={t('meetings.propose.urlPlaceholder')}
          autoCapitalize="none"
          keyboardType="url"
        />

        {error && (
          <Text
            testID="propose-error"
            className="font-body text-body-sm text-danger-text mb-3"
          >
            {error}
          </Text>
        )}

        <View className="flex-row gap-3 mt-2">
          <View className="flex-1">
            <Button
              testID="propose-cancel"
              variant="outline"
              onPress={onClose}
              disabled={propose.isPending}
            >
              {t('meetings.propose.cancel')}
            </Button>
          </View>
          <View className="flex-1">
            <Button
              testID="propose-submit"
              variant="primary"
              onPress={onSubmit}
              loading={propose.isPending}
            >
              {t('meetings.propose.send')}
            </Button>
          </View>
        </View>
      </ScrollView>
    </BottomSheet>
  );
}
