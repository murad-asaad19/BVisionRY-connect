import { useState } from 'react';
import { View, Text } from 'react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { OutcomeSchema } from '~/features/meetings/schemas';
import {
  submitMeetingReview,
  type MeetingOutcome,
} from '~/features/meetings/services/meetings.service';

type Props = {
  visible: boolean;
  onClose: () => void;
  meetingId: string;
};

export function PostConnectionReview({ visible, onClose, meetingId }: Props) {
  const { t } = useTranslation();
  const [outcome, setOutcome] = useState<MeetingOutcome | null>(null);
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const qc = useQueryClient();

  const submit = useMutation({
    mutationFn: () =>
      submitMeetingReview({ meetingId, outcome: outcome!, note: note.trim() || null }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pending-meeting-reviews'] });
      setOutcome(null);
      setNote('');
      onClose();
    },
    onError: (e) =>
      setError(e instanceof Error ? e.message : t('meetings.review.submitFailed')),
  });

  const pick = (next: MeetingOutcome) => {
    setOutcome(next);
    setError(null);
  };

  const onSubmit = () => {
    setError(null);
    const parsed = OutcomeSchema.safeParse(outcome);
    if (!parsed.success) {
      setError(t('meetings.review.pickOutcome'));
      return;
    }
    submit.mutate();
  };

  return (
    <BottomSheet visible={visible} onClose={onClose} testID="post-connection-review">
      <Text className="font-display-bold text-[16px] text-navy mb-1">
        {t('meetings.review.title')}
      </Text>
      <Text className="font-body text-[12px] text-muted mb-3">
        {t('meetings.review.subtitle')}
      </Text>

      <View className="gap-2 mb-3">
        <Button
          testID="review-outcome-useful"
          variant={outcome === 'useful' ? 'primary' : 'outline'}
          onPress={() => pick('useful')}
        >
          {t('meetings.review.useful')}
        </Button>
        <Button
          testID="review-outcome-not_useful"
          variant={outcome === 'not_useful' ? 'primary' : 'outline'}
          onPress={() => pick('not_useful')}
        >
          {t('meetings.review.notUseful')}
        </Button>
        <Button
          testID="review-outcome-no_show"
          variant={outcome === 'no_show' ? 'danger' : 'outline'}
          onPress={() => pick('no_show')}
        >
          {t('meetings.review.noShow')}
        </Button>
      </View>

      <Input
        testID="review-note"
        value={note}
        onChangeText={setNote}
        placeholder={t('meetings.review.notePlaceholder')}
        multiline
        numberOfLines={4}
        maxLength={1000}
      />
      {error ? (
        <Text testID="review-error" className="text-danger-text text-[11px] mb-2 font-body">
          {error}
        </Text>
      ) : null}
      <View className="flex-row gap-3 mt-1">
        <View className="flex-1">
          <Button
            testID="review-cancel"
            variant="outline"
            onPress={onClose}
            disabled={submit.isPending}
          >
            {t('meetings.review.skip')}
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="review-submit"
            variant="primary"
            onPress={onSubmit}
            loading={submit.isPending}
          >
            {t('meetings.review.submit')}
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
