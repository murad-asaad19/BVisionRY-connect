import { useState } from 'react';
import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { AvatarCircle } from '~/components/ui/AvatarCircle';
import { Banner } from '~/components/ui/Banner';
import { IntroNoteSchema } from '~/features/intros/schemas';
import { useRequestWarmIntro } from '~/features/intros/hooks/useRequestWarmIntro';
import {
  IntroDuplicateError,
  IntroRateLimitError,
} from '~/features/intros/services/intros.service';

export type WarmIntroComposeTarget = {
  mutualId: string;
  mutualName: string;
  mutualHandle?: string | null;
  mutualPhotoUrl?: string | null;
  targetId: string;
  targetName: string;
  targetHandle?: string | null;
};

type Props = {
  visible: boolean;
  /** Triple identifying the (mutual, target) pair the viewer is asking. Required while visible. */
  context: WarmIntroComposeTarget | null;
  onClose: () => void;
  onSent: () => void;
};

const NOTE_MIN = 80;
const NOTE_MAX = 400;

/**
 * Modal sheet for sending a warm-intro request: viewer asks `mutual`
 * to introduce them to `target`. Reuses the existing 80-400 char
 * window so the note schema stays consistent with direct intros.
 */
export function WarmIntroComposeSheet({ visible, context, onClose, onSent }: Props) {
  const { t } = useTranslation();
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);
  const send = useRequestWarmIntro();

  const charCount = note.trim().length;
  const inRange = charCount >= NOTE_MIN && charCount <= NOTE_MAX;

  const reset = () => {
    setNote('');
    setError(null);
  };

  const onSubmit = async () => {
    if (!context) return;
    if (send.isPending) return;
    setError(null);
    const parsed = IntroNoteSchema.safeParse(note);
    if (!parsed.success) {
      setError(t('intros.compose.errorRange'));
      return;
    }
    try {
      await send.mutateAsync({
        mutualId: context.mutualId,
        targetId: context.targetId,
        note: parsed.data,
      });
      setSuccessBanner(t('intros.warm.composeSuccess', { mutualName: context.mutualName }));
      reset();
      onSent();
    } catch (e) {
      if (e instanceof IntroDuplicateError) setError(t('intros.compose.errorDuplicate'));
      else if (e instanceof IntroRateLimitError) setError(t('intros.compose.errorRateLimit'));
      else setError(t('intros.compose.errorGeneric'));
    }
  };

  const onCloseInternal = () => {
    setSuccessBanner(null);
    reset();
    onClose();
  };

  if (!context) {
    return (
      <BottomSheet visible={visible} onClose={onCloseInternal} testID="warm-intro-compose-sheet">
        <View className="py-6 items-center">
          <Text className="font-body text-[13px] text-muted">…</Text>
        </View>
      </BottomSheet>
    );
  }

  return (
    <BottomSheet
      visible={visible}
      onClose={onCloseInternal}
      testID="warm-intro-compose-sheet"
      dismissible={!send.isPending}
    >
      <Text className="font-display-bold text-[16px] text-navy mb-2">
        {t('intros.warm.composeTitle', { mutualName: context.mutualName })}
      </Text>

      {/* Mutual preview card so it's obvious whose inbox this lands in. */}
      <View
        testID="warm-intro-compose-mutual"
        className="bg-gold-pale border border-gold rounded-xl p-3 mb-3 flex-row items-center gap-2.5"
      >
        <AvatarCircle name={context.mutualName} photoUrl={context.mutualPhotoUrl ?? null} size={48} />
        <View className="flex-1 min-w-0">
          <Text className="font-display-bold text-[13px] text-navy" numberOfLines={1}>
            {context.mutualName}
          </Text>
          {context.mutualHandle ? (
            <Text className="font-body text-[11px] text-muted" numberOfLines={1}>
              @{context.mutualHandle}
            </Text>
          ) : null}
        </View>
      </View>

      {successBanner ? (
        <View testID="warm-intro-compose-success" className="mb-3">
          <Banner variant="success">{successBanner}</Banner>
        </View>
      ) : null}

      <Input
        testID="warm-intro-compose-note"
        value={note}
        onChangeText={(s) => {
          setNote(s);
          setError(null);
        }}
        multiline
        numberOfLines={6}
        maxLength={NOTE_MAX}
        placeholder={t('intros.warm.composePlaceholder', {
          mutualName: context.mutualName,
          targetName: context.targetName,
        })}
        errorText={error ?? undefined}
      />

      <Text className={`font-body text-[11px] ${inRange ? 'text-success-text' : 'text-muted'} mb-2`}>
        {t('intros.compose.counter', { count: charCount, max: NOTE_MAX, min: NOTE_MIN })}
      </Text>

      <View className="flex-row gap-3 mt-1">
        <View className="flex-1">
          <Button
            testID="warm-intro-compose-cancel"
            variant="outline"
            onPress={onCloseInternal}
            disabled={send.isPending}
          >
            {t('intros.compose.cancel')}
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="warm-intro-compose-send"
            variant="primary"
            onPress={onSubmit}
            loading={send.isPending}
          >
            {t('intros.warm.composeSubmit')}
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
