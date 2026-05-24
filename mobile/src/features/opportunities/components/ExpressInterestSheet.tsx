import { useState } from 'react';
import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { BottomSheet } from '~/components/ui/Modal';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { useToast } from '~/components/ui/Toast';
import { useExpressInterest } from '~/features/opportunities/hooks/useExpressInterest';

type Props = {
  visible: boolean;
  opportunityId: string;
  opportunityTitle?: string;
  onClose: () => void;
  onSent?: () => void;
};

const NOTE_MAX = 500;

export function ExpressInterestSheet({
  visible,
  opportunityId,
  opportunityTitle,
  onClose,
  onSent,
}: Props) {
  const { t } = useTranslation();
  const toast = useToast();
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const mutate = useExpressInterest();

  const submit = async () => {
    if (mutate.isPending) return;
    setError(null);
    // Optional note: if provided, must be 10-500 chars.
    const trimmed = note.trim();
    if (trimmed.length > 0 && trimmed.length < 10) {
      setError(t('opportunities.interest.errorNoteRange'));
      return;
    }
    try {
      await mutate.mutateAsync({
        opportunityId,
        note: trimmed.length > 0 ? trimmed : undefined,
      });
      setNote('');
      toast.success(t('opportunities.interest.success'));
      onSent?.();
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : t('opportunities.interest.errorGeneric'));
    }
  };

  return (
    <BottomSheet
      visible={visible}
      onClose={onClose}
      testID="express-interest-sheet"
      dismissible={!mutate.isPending}
    >
      {opportunityTitle ? (
        <Text className="font-display-bold text-body-lg text-navy mb-1" numberOfLines={2}>
          {opportunityTitle}
        </Text>
      ) : null}
      <Text className="font-body text-body-md text-muted mb-3">
        {t('opportunities.interest.subtitle')}
      </Text>

      <Input
        testID="express-interest-note"
        value={note}
        onChangeText={(s) => {
          setNote(s);
          setError(null);
        }}
        multiline
        numberOfLines={4}
        maxLength={NOTE_MAX}
        placeholder={t('opportunities.interest.notePlaceholder')}
        errorText={error ?? undefined}
      />

      <View className="flex-row gap-3 mt-2">
        <View className="flex-1">
          <Button
            testID="express-interest-cancel"
            variant="outline"
            onPress={onClose}
            disabled={mutate.isPending}
          >
            {t('common.cancel')}
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="express-interest-submit"
            variant="primary"
            onPress={submit}
            loading={mutate.isPending}
          >
            {t('opportunities.interest.submit')}
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
