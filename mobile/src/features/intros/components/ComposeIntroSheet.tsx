import { useEffect, useRef, useState } from 'react';
import { View, Text } from 'react-native';
import { useTranslation } from 'react-i18next';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { IntroNoteSchema } from '~/features/intros/schemas';
import { useSendIntro } from '~/features/intros/hooks/useSendIntro';
import {
  IntroCooldownError,
  IntroDuplicateError,
  IntroExpiredError,
  IntroRateLimitError,
} from '~/features/intros/services/intros.service';
import { BottomSheet } from '~/components/ui/Modal';
import { Button } from '~/components/ui/Button';
import { Input } from '~/components/ui/Input';
import { AvatarCircle } from '~/components/ui/AvatarCircle';

type Props = {
  visible: boolean;
  recipientId: string;
  recipientName: string;
  /** Optional preview data for the gold recipient card at the top of the sheet. */
  recipientHandle?: string | null;
  recipientHeadline?: string | null;
  recipientPhotoUrl?: string | null;
  onClose: () => void;
  onSent: () => void;
};

const NOTE_MIN = 80;
const NOTE_MAX = 400;
const DRAFT_KEY_PREFIX = 'intro-draft-v1:';

export function ComposeIntroSheet({
  visible,
  recipientId,
  recipientName,
  recipientHandle,
  recipientHeadline,
  recipientPhotoUrl,
  onClose,
  onSent,
}: Props) {
  const { t } = useTranslation();
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const send = useSendIntro();

  // Per-recipient draft persistence (AsyncStorage). Hydrate on open, persist
  // on every change, clear on successful send. Cancel keeps the draft so the
  // user can resume; explicit clear-on-send avoids re-sending stale text.
  const draftKey = `${DRAFT_KEY_PREFIX}${recipientId}`;
  const hydratedRef = useRef(false);

  useEffect(() => {
    if (!visible) {
      hydratedRef.current = false;
      return;
    }
    let cancelled = false;
    void AsyncStorage.getItem(draftKey).then((stored) => {
      if (!cancelled) {
        setNote(stored ?? '');
        hydratedRef.current = true;
      }
    });
    return () => {
      cancelled = true;
    };
  }, [visible, draftKey]);

  useEffect(() => {
    if (!visible || !hydratedRef.current) return;
    if (note.length === 0) void AsyncStorage.removeItem(draftKey);
    else void AsyncStorage.setItem(draftKey, note);
  }, [note, visible, draftKey]);

  const charCount = note.trim().length;
  const inRange = charCount >= NOTE_MIN && charCount <= NOTE_MAX;

  const onSubmit = async () => {
    // Double-submit guard — a fast double-tap (or async-induced re-render)
    // must never fire two RPCs. The DB unique index catches the second one
    // but the UX is cleaner if we never attempt it.
    if (send.isPending) return;

    setError(null);
    const parsed = IntroNoteSchema.safeParse(note);
    if (!parsed.success) {
      setError(t('intros.compose.errorRange'));
      return;
    }
    try {
      await send.mutateAsync({ recipientId, note: parsed.data });
      await AsyncStorage.removeItem(draftKey);
      setNote('');
      onSent();
    } catch (e) {
      if (e instanceof IntroDuplicateError) setError(t('intros.compose.errorDuplicate'));
      else if (e instanceof IntroCooldownError) setError(t('intros.compose.errorCooldown'));
      else if (e instanceof IntroRateLimitError) setError(t('intros.compose.errorRateLimit'));
      else if (e instanceof IntroExpiredError) setError(t('intros.compose.errorExpired'));
      else setError(t('intros.compose.errorGeneric'));
    }
  };

  return (
    <BottomSheet
      visible={visible}
      onClose={onClose}
      testID="compose-intro-sheet"
      dismissible={!send.isPending}
    >
      {/* Recipient preview card (mockup E1) */}
      <View
        testID="compose-intro-recipient"
        className="bg-gold-pale border border-gold rounded-xl p-3 mb-3 flex-row items-center gap-2.5"
      >
        <AvatarCircle name={recipientName} photoUrl={recipientPhotoUrl ?? null} size={48} />
        <View className="flex-1 min-w-0">
          <Text className="font-display-bold text-[14px] text-navy" numberOfLines={1}>
            {recipientName}
          </Text>
          {recipientHandle ? (
            <Text className="font-body text-[11px] text-muted" numberOfLines={1}>
              @{recipientHandle}
            </Text>
          ) : null}
          {recipientHeadline ? (
            <Text className="font-body text-[11px] text-body mt-0.5" numberOfLines={2}>
              {recipientHeadline}
            </Text>
          ) : null}
        </View>
      </View>

      <Text className="font-body text-[12px] text-muted mb-3">{t('intros.compose.hint')}</Text>

      <Input
        testID="compose-intro-note"
        value={note}
        onChangeText={(s) => {
          setNote(s);
          setError(null);
        }}
        multiline
        numberOfLines={6}
        maxLength={NOTE_MAX}
        placeholder={t('intros.compose.placeholder')}
        errorText={error ?? undefined}
      />
      <Text
        className={`font-body text-[11px] ${inRange ? 'text-success-text' : 'text-muted'} mb-2`}
      >
        {t('intros.compose.counter', { count: charCount, max: NOTE_MAX, min: NOTE_MIN })}
      </Text>

      <View className="flex-row gap-3 mt-1">
        <View className="flex-1">
          <Button
            testID="compose-intro-cancel"
            variant="outline"
            onPress={onClose}
            disabled={send.isPending}
          >
            {t('intros.compose.cancel')}
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="compose-intro-send"
            variant="primary"
            onPress={onSubmit}
            loading={send.isPending}
          >
            {t('intros.compose.send')}
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
