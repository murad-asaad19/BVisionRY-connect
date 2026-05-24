import { useEffect, useState } from 'react';
import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { BottomSheet } from '~/components/ui/Modal';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { useBookSlot } from '~/features/office-hours/hooks/useBookSlot';
import { BookSlotInputSchema } from '~/features/office-hours/schemas';
import type { UpcomingSlot } from '~/features/office-hours/services/officeHours.service';

type Props = {
  visible: boolean;
  hostId: string;
  hostName: string;
  slot: UpcomingSlot | null;
  onClose: () => void;
  onBooked?: (proposalId: string) => void;
};

const TOPIC_MAX = 280;

export function BookSlotSheet({ visible, hostId, hostName, slot, onClose, onBooked }: Props) {
  const { t } = useTranslation();
  const [topic, setTopic] = useState('');
  const [error, setError] = useState<string | null>(null);
  const mutate = useBookSlot();

  useEffect(() => {
    if (!visible) {
      setTopic('');
      setError(null);
    }
  }, [visible]);

  const submit = async () => {
    if (mutate.isPending || !slot) return;
    setError(null);
    const parsed = BookSlotInputSchema.safeParse({ slotId: slot.id, topic });
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? 'invalid');
      return;
    }
    try {
      const proposalId = await mutate.mutateAsync({
        hostId,
        slotId: parsed.data.slotId,
        topic: parsed.data.topic,
      });
      onBooked?.(proposalId);
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'failed');
    }
  };

  return (
    <BottomSheet
      visible={visible}
      onClose={onClose}
      testID="book-slot-sheet"
      dismissible={!mutate.isPending}
    >
      <Text className="font-display-bold text-[14px] text-navy mb-1">
        {t('officeHours.book.title', { hostName })}
      </Text>
      {slot?.hostNotesTemplate ? (
        <Text className="font-body text-[11px] text-muted mb-3">{slot.hostNotesTemplate}</Text>
      ) : null}

      <Text className="font-display-semibold text-[11px] text-muted mb-1">
        {t('officeHours.book.topicLabel')}
      </Text>
      <Input
        testID="book-slot-topic"
        value={topic}
        onChangeText={(s) => {
          setTopic(s);
          setError(null);
        }}
        multiline
        numberOfLines={4}
        maxLength={TOPIC_MAX}
        placeholder={t('officeHours.book.topicPlaceholder')}
        errorText={error ?? undefined}
      />

      <View className="flex-row gap-3 mt-2">
        <View className="flex-1">
          <Button
            testID="book-slot-cancel"
            variant="outline"
            onPress={onClose}
            disabled={mutate.isPending}
          >
            {t('common.cancel')}
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="book-slot-submit"
            variant="primary"
            onPress={submit}
            loading={mutate.isPending}
          >
            {t('officeHours.book.submit')}
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
