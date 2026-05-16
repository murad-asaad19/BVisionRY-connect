import { useState } from 'react';
import { View, Text } from 'react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
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
    onError: (e) => setError(e instanceof Error ? e.message : 'Submit failed'),
  });

  const pick = (next: MeetingOutcome) => {
    setOutcome(next);
    setError(null);
  };

  const onSubmit = () => {
    setError(null);
    if (!outcome) {
      setError('Pick an outcome.');
      return;
    }
    submit.mutate();
  };

  return (
    <BottomSheet visible={visible} onClose={onClose} testID="post-connection-review">
      <Text className="font-display-bold text-[16px] text-navy mb-1">How was the meeting?</Text>
      <Text className="font-body text-[12px] text-muted mb-3">
        Your answer helps us improve match quality. Optional note for your records.
      </Text>

      <View className="gap-2 mb-3">
        <Button
          testID="review-outcome-useful"
          variant={outcome === 'useful' ? 'primary' : 'outline'}
          onPress={() => pick('useful')}
        >
          👍 Useful
        </Button>
        <Button
          testID="review-outcome-not_useful"
          variant={outcome === 'not_useful' ? 'primary' : 'outline'}
          onPress={() => pick('not_useful')}
        >
          😐 Not useful
        </Button>
        <Button
          testID="review-outcome-no_show"
          variant={outcome === 'no_show' ? 'danger' : 'outline'}
          onPress={() => pick('no_show')}
        >
          🚫 No-show
        </Button>
      </View>

      <Input
        testID="review-note"
        value={note}
        onChangeText={setNote}
        placeholder="Optional note…"
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
            Skip
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="review-submit"
            variant="primary"
            onPress={onSubmit}
            loading={submit.isPending}
          >
            Submit
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
