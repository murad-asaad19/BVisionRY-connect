import { useState } from 'react';
import { View, Text, ScrollView, Pressable } from 'react-native';
import { useProposeMeeting } from '~/features/meetings/hooks/useProposeMeeting';
import { SlotsSchema, DurationSchema, MeetingUrlSchema } from '~/features/meetings/schemas';
import { DateTimeField } from './DateTimeField';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { Pill } from '~/components/ui/Pill';

type Props = {
  visible: boolean;
  conversationId: string;
  onClose: () => void;
  onSent: () => void;
};

const DURATIONS = [15, 30, 45, 60, 90, 120];

export function ProposeMeetingSheet({ visible, conversationId, onClose, onSent }: Props) {
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
    const slots = [slot1, slot2, slot3].filter((s) => s.length > 0);
    const slotsParsed = SlotsSchema.safeParse(slots);
    if (!slotsParsed.success) {
      setError('Pick 1-3 future date/times.');
      return;
    }
    const durationParsed = DurationSchema.safeParse(duration);
    if (!durationParsed.success) {
      setError('Duration must be 15-240 minutes.');
      return;
    }
    const urlParsed = MeetingUrlSchema.safeParse(url);
    if (!urlParsed.success) {
      setError('Meeting URL must start with https:// (or leave blank).');
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
      reset();
      onSent();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Propose failed');
    }
  };

  return (
    <BottomSheet visible={visible} onClose={onClose} testID="propose-meeting-sheet">
      <ScrollView>
        <Text className="font-display-bold text-[16px] text-navy mb-1">Propose a meeting</Text>
        <Text className="font-body text-[12px] text-muted mb-3">
          Pick 1-3 time options. The other person picks one.
        </Text>

        <DateTimeField
          value={slot1}
          onChange={setSlot1}
          testID="propose-slot-1"
          label="Slot 1 (required)"
        />
        <DateTimeField
          value={slot2}
          onChange={setSlot2}
          testID="propose-slot-2"
          label="Slot 2 (optional)"
        />
        <DateTimeField
          value={slot3}
          onChange={setSlot3}
          testID="propose-slot-3"
          label="Slot 3 (optional)"
        />

        <Text className="font-display-semibold text-[10px] text-muted uppercase tracking-wide mb-1.5 mt-1">
          Duration
        </Text>
        <View className="flex-row flex-wrap gap-2 mb-3">
          {DURATIONS.map((d) => (
            <Pressable
              key={d}
              testID={`propose-duration-${d}`}
              onPress={() => setDuration(d)}
              accessibilityRole="button"
              accessibilityState={{ selected: duration === d }}
            >
              <Pill variant={duration === d ? 'solid' : 'outline'}>{`${d} min`}</Pill>
            </Pressable>
          ))}
        </View>

        <Input
          testID="propose-url"
          label="Meeting URL (optional)"
          value={url}
          onChangeText={setUrl}
          placeholder="https://meet.google.com/abc-defg-hij"
          autoCapitalize="none"
          keyboardType="url"
        />

        {error && (
          <Text testID="propose-error" className="text-danger-text mb-3">
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
              Cancel
            </Button>
          </View>
          <View className="flex-1">
            <Button
              testID="propose-submit"
              variant="primary"
              onPress={onSubmit}
              loading={propose.isPending}
            >
              Send
            </Button>
          </View>
        </View>
      </ScrollView>
    </BottomSheet>
  );
}
