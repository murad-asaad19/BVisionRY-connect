import { useState } from 'react';
import { Modal, View, Text, Alert } from 'react-native';
import { useReportTarget } from '~/features/privacy/hooks/useReportTarget';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import type { ReportReason, ReportTargetType } from '~/features/privacy/services/privacy.service';

const REASONS: { value: ReportReason; label: string }[] = [
  { value: 'spam', label: 'Spam' },
  { value: 'harassment', label: 'Harassment' },
  { value: 'impersonation', label: 'Impersonation' },
  { value: 'inappropriate', label: 'Inappropriate content' },
  { value: 'other', label: 'Other' },
];

type Props = {
  visible: boolean;
  targetType: ReportTargetType;
  targetId: string;
  /** Optional quote-back of the offending message for chat reports. */
  messageBody?: string;
  onClose: () => void;
};

export function ReportModal({ visible, targetType, targetId, messageBody, onClose }: Props) {
  const [reason, setReason] = useState<ReportReason | null>(null);
  const [note, setNote] = useState('');
  const report = useReportTarget();

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <View className="flex-1 justify-end bg-navy/50">
        <View testID="report-modal" className="bg-white rounded-t-3xl p-5">
          <View className="self-center w-9 h-1 bg-border rounded-full mb-3" />
          <Text className="font-display-bold text-[16px] text-navy mb-3">Report</Text>

          {messageBody ? (
            <View
              testID="report-quoted-message"
              className="border-l-4 border-danger-text bg-slate-100 rounded-r-[10px] px-3 py-2 mb-3"
            >
              <Text className="font-display-bold text-[10px] uppercase tracking-wide text-muted mb-0.5">
                Quoted message
              </Text>
              <Text className="font-body text-[12px] text-body leading-snug" numberOfLines={4}>
                {messageBody}
              </Text>
            </View>
          ) : null}

          <View className="gap-2 mb-3">
            {REASONS.map((r) => (
              <Button
                key={r.value}
                testID={`report-reason-${r.value}`}
                variant={reason === r.value ? 'primary' : 'outline'}
                onPress={() => setReason(r.value)}
              >
                {r.label}
              </Button>
            ))}
          </View>

          <Input
            testID="report-note"
            label="Additional details (optional)"
            value={note}
            onChangeText={setNote}
            placeholder="What happened?"
            multiline
            numberOfLines={3}
            maxLength={1000}
          />

          <View className="flex-row gap-2 mt-2">
            <View className="flex-1">
              <Button testID="report-cancel" variant="outline" onPress={onClose}>
                Cancel
              </Button>
            </View>
            <View className="flex-1">
              <Button
                testID="report-submit"
                variant="danger"
                loading={report.isPending}
                onPress={() => {
                  if (!reason) {
                    Alert.alert('Pick a reason', 'Select what to report before submitting.');
                    return;
                  }
                  report.mutate(
                    { targetType, targetId, reason, note: note.trim() || null },
                    {
                      onSuccess: () => {
                        Alert.alert('Reported', 'Thank you, the team will review.');
                        setNote('');
                        setReason(null);
                        onClose();
                      },
                      onError: (e) => Alert.alert('Report failed', (e as Error).message),
                    }
                  );
                }}
              >
                Submit
              </Button>
            </View>
          </View>
        </View>
      </View>
    </Modal>
  );
}
