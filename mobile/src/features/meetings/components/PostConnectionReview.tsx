import { useState } from 'react';
import { View, Text, Pressable } from 'react-native';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { ThumbsUp, Meh, Ban } from 'lucide-react-native';
import type { LucideIcon } from 'lucide-react-native';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { useToast } from '~/components/ui/Toast';
import { colors } from '~/theme/colors';
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

type OutcomeOption = {
  value: MeetingOutcome;
  labelKey: string;
  icon: LucideIcon;
  destructive?: boolean;
};

const OUTCOMES: OutcomeOption[] = [
  { value: 'useful', labelKey: 'meetings.review.useful', icon: ThumbsUp },
  { value: 'not_useful', labelKey: 'meetings.review.notUseful', icon: Meh },
  { value: 'no_show', labelKey: 'meetings.review.noShow', icon: Ban, destructive: true },
];

export function PostConnectionReview({ visible, onClose, meetingId }: Props) {
  const { t } = useTranslation();
  const toast = useToast();
  const [outcome, setOutcome] = useState<MeetingOutcome | null>(null);
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const qc = useQueryClient();

  const submit = useMutation({
    mutationFn: () =>
      submitMeetingReview({ meetingId, outcome: outcome!, note: note.trim() || null }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pending-meeting-reviews'] });
      toast.success(t('meetings.review.submit'));
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
      <Text className="font-display-bold text-display-md text-navy mb-1">
        {t('meetings.review.title')}
      </Text>
      <Text className="font-body text-body-md text-muted mb-3">
        {t('meetings.review.subtitle')}
      </Text>

      <View className="gap-2 mb-3">
        {OUTCOMES.map((opt) => {
          const active = outcome === opt.value;
          // Picked-state styling: destructive options use the danger palette
          // when active so the user gets clear feedback that "no-show" carries
          // weight; the others use the standard primary navy.
          const containerCls = active
            ? opt.destructive
              ? 'bg-danger-bg border-danger-border'
              : 'bg-navy border-navy'
            : 'bg-white border-border';
          const textCls = active
            ? opt.destructive
              ? 'text-danger-text'
              : 'text-white'
            : 'text-body';
          const iconColor = active
            ? opt.destructive
              ? colors.danger
              : colors.white
            : colors.navy;
          return (
            <Pressable
              key={opt.value}
              testID={`review-outcome-${opt.value}`}
              onPress={() => pick(opt.value)}
              accessibilityRole="radio"
              accessibilityState={{ selected: active }}
              accessibilityLabel={t(opt.labelKey)}
              className={`flex-row items-center gap-2 border rounded-xl px-card-lg py-3 ${containerCls}`}
            >
              <opt.icon size={18} color={iconColor} />
              <Text className={`font-display-semibold text-display-sm ${textCls}`}>
                {t(opt.labelKey)}
              </Text>
            </Pressable>
          );
        })}
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
        <Text
          testID="review-error"
          className="font-body text-body-sm text-danger-text mb-2 mt-1"
        >
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
