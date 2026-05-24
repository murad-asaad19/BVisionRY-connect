import { useEffect, useState } from 'react';
import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { Banner } from '~/components/ui/Banner';
import { IntroNoteSchema } from '~/features/intros/schemas';
import { useForwardWarmIntro } from '~/features/intros/hooks/useForwardWarmIntro';
import { IntroDuplicateError } from '~/features/intros/services/intros.service';

type Props = {
  visible: boolean;
  introId: string;
  /** Original asker's first name — used to seed the note template. */
  askerFirstName: string;
  /** Target's full name. */
  targetName: string;
  /** Target's first name — used to seed the note template. */
  targetFirstName: string;
  /** Optional target preview fields for the gold header card. */
  targetHandle?: string | null;
  targetPhotoUrl?: string | null;
  /** Original asker's note — included in the template so the mutual can mention context. */
  originalNote: string;
  onClose: () => void;
  onForwarded: () => void;
};

/**
 * Sheet opened by the recipient of a `warm_request` intro to forward
 * it to the original target. Pre-fills the textarea with a friendly
 * template so the mutual doesn't have to start from scratch; they can
 * edit before sending.
 */
export function WarmIntroForwardSheet({
  visible,
  introId,
  askerFirstName,
  targetName,
  targetFirstName,
  targetHandle,
  targetPhotoUrl,
  originalNote,
  onClose,
  onForwarded,
}: Props) {
  const { t } = useTranslation();
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);
  const forward = useForwardWarmIntro();

  // Pre-fill the textarea each time the sheet opens with a fresh
  // template. Edit-then-cancel discards; users get a clean slate next
  // time they open the sheet.
  useEffect(() => {
    if (!visible) return;
    const template = `Hey ${targetFirstName}, meet my friend ${askerFirstName}. ${originalNote}`;
    setNote(template);
    setError(null);
    setSuccessBanner(null);
  }, [visible, askerFirstName, targetFirstName, originalNote]);

  const charCount = note.trim().length;
  const inRange = charCount >= 80 && charCount <= 400;

  const onSubmit = async () => {
    if (forward.isPending) return;
    setError(null);
    const parsed = IntroNoteSchema.safeParse(note);
    if (!parsed.success) {
      setError(t('intros.compose.errorRange'));
      return;
    }
    try {
      await forward.mutateAsync({ introId, note: parsed.data });
      setSuccessBanner(t('intros.warm.forwardSuccess', { targetName }));
      onForwarded();
    } catch (e) {
      if (e instanceof IntroDuplicateError) setError(t('intros.compose.errorDuplicate'));
      else setError(t('intros.compose.errorGeneric'));
    }
  };

  return (
    <BottomSheet
      visible={visible}
      onClose={onClose}
      testID="warm-intro-forward-sheet"
      dismissible={!forward.isPending}
    >
      <Text className="font-display-bold text-display-md text-navy mb-2">
        {t('intros.warm.forwardTitle', { targetName })}
      </Text>

      <View
        testID="warm-intro-forward-target"
        className="bg-gold-pale border border-gold rounded-xl p-card mb-3 flex-row items-center gap-2.5"
      >
        <AvatarCircle name={targetName} photoUrl={targetPhotoUrl ?? null} size={48} />
        <View className="flex-1 min-w-0">
          <Text className="font-display-bold text-display-sm text-navy" numberOfLines={1}>
            {targetName}
          </Text>
          {targetHandle ? (
            <Text className="font-body text-body-sm text-muted" numberOfLines={1}>
              @{targetHandle}
            </Text>
          ) : null}
        </View>
      </View>

      {successBanner ? (
        <View testID="warm-intro-forward-success" className="mb-3">
          <Banner variant="success">{successBanner}</Banner>
        </View>
      ) : null}

      <Input
        testID="warm-intro-forward-note"
        value={note}
        onChangeText={(s) => {
          setNote(s);
          setError(null);
        }}
        multiline
        numberOfLines={6}
        maxLength={400}
        placeholder={t('intros.warm.forwardPlaceholder')}
        errorText={error ?? undefined}
      />

      <Text className={`font-body text-body-sm ${inRange ? 'text-success-text' : 'text-muted'} mb-2`}>
        {t('intros.compose.counter', { count: charCount, max: 400, min: 80 })}
      </Text>

      <View className="flex-row gap-3 mt-1">
        <View className="flex-1">
          <Button
            testID="warm-intro-forward-cancel"
            variant="outline"
            onPress={onClose}
            disabled={forward.isPending}
          >
            {t('intros.compose.cancel')}
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="warm-intro-forward-send"
            variant="primary"
            onPress={onSubmit}
            loading={forward.isPending}
          >
            {t('intros.warm.forwardSubmit')}
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
