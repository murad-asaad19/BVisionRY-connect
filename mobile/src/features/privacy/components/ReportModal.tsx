import { useState } from 'react';
import { Modal, View, Text, Alert } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useReportTarget } from '~/features/privacy/hooks/useReportTarget';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import type { ReportReason, ReportTargetType } from '~/features/privacy/services/privacy.service';

const REASON_VALUES: ReportReason[] = [
  'spam',
  'harassment',
  'impersonation',
  'inappropriate',
  'other',
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
  const { t } = useTranslation();
  const [reason, setReason] = useState<ReportReason | null>(null);
  const [note, setNote] = useState('');
  const report = useReportTarget();

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <View className="flex-1 justify-end bg-navy/50">
        <View testID="report-modal" className="bg-white rounded-t-3xl p-5">
          <View className="self-center w-9 h-1 bg-border rounded-full mb-3" />
          <Text className="font-display-bold text-[16px] text-navy mb-3">
            {t('privacy.reportModal.title')}
          </Text>

          {messageBody ? (
            <View
              testID="report-quoted-message"
              className="border-l-4 border-danger-text bg-slate-100 rounded-r-[10px] px-3 py-2 mb-3"
            >
              <Text className="font-display-bold text-[10px] uppercase tracking-wide text-muted mb-0.5">
                {t('privacy.reportModal.quoted')}
              </Text>
              <Text className="font-body text-[12px] text-body leading-snug" numberOfLines={4}>
                {messageBody}
              </Text>
            </View>
          ) : null}

          <View className="gap-2 mb-3">
            {REASON_VALUES.map((value) => (
              <Button
                key={value}
                testID={`report-reason-${value}`}
                variant={reason === value ? 'primary' : 'outline'}
                onPress={() => setReason(value)}
              >
                {t(`privacy.reportModal.reasons.${value}`)}
              </Button>
            ))}
          </View>

          <Input
            testID="report-note"
            label={t('privacy.reportModal.noteLabel')}
            value={note}
            onChangeText={setNote}
            placeholder={t('privacy.reportModal.notePlaceholder')}
            multiline
            numberOfLines={3}
            maxLength={1000}
          />

          <View className="flex-row gap-2 mt-2">
            <View className="flex-1">
              <Button testID="report-cancel" variant="outline" onPress={onClose}>
                {t('privacy.reportModal.cancel')}
              </Button>
            </View>
            <View className="flex-1">
              <Button
                testID="report-submit"
                variant="danger"
                loading={report.isPending}
                onPress={() => {
                  if (!reason) {
                    Alert.alert(
                      t('privacy.reportModal.pickReasonTitle'),
                      t('privacy.reportModal.pickReasonBody')
                    );
                    return;
                  }
                  report.mutate(
                    { targetType, targetId, reason, note: note.trim() || null },
                    {
                      onSuccess: () => {
                        Alert.alert(
                          t('privacy.reportModal.sentTitle'),
                          t('privacy.reportModal.sentBody')
                        );
                        setNote('');
                        setReason(null);
                        onClose();
                      },
                      onError: (e) =>
                        Alert.alert(t('privacy.reportModal.failedTitle'), (e as Error).message),
                    }
                  );
                }}
              >
                {t('privacy.reportModal.submit')}
              </Button>
            </View>
          </View>
        </View>
      </View>
    </Modal>
  );
}
