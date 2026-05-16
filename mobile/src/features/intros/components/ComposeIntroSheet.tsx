import { useState } from 'react';
import { View, Text } from 'react-native';
import { IntroNoteSchema } from '~/features/intros/schemas';
import { useSendIntro } from '~/features/intros/hooks/useSendIntro';
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
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const send = useSendIntro();

  const charCount = note.trim().length;
  const inRange = charCount >= 80 && charCount <= 400;

  const onSubmit = async () => {
    setError(null);
    const parsed = IntroNoteSchema.safeParse(note);
    if (!parsed.success) {
      setError('Note must be 80-400 characters.');
      return;
    }
    try {
      await send.mutateAsync({ recipientId, note: parsed.data });
      setNote('');
      onSent();
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Send failed';
      if (/duplicate key|intros_active_pair_uq/i.test(msg)) {
        setError('You already have a pending intro to this user.');
      } else {
        setError(msg);
      }
    }
  };

  return (
    <BottomSheet visible={visible} onClose={onClose} testID="compose-intro-sheet">
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

      <Text className="font-body text-[12px] text-muted mb-3">
        Say why you want to connect. Min 80 characters. Your message goes through a quick safety
        check before delivery.
      </Text>

      <Input
        testID="compose-intro-note"
        value={note}
        onChangeText={(t) => {
          setNote(t);
          setError(null);
        }}
        multiline
        numberOfLines={6}
        maxLength={400}
        placeholder="I'm reaching out because..."
      />
      <Text
        className={`font-body text-[11px] ${inRange ? 'text-success-text' : 'text-muted'} mb-2`}
      >
        {charCount} / 400 (min 80)
      </Text>

      {error && (
        <Text testID="compose-intro-error" className="text-danger-text font-body text-[12px] mb-2">
          {error}
        </Text>
      )}

      <View className="flex-row gap-3 mt-1">
        <View className="flex-1">
          <Button
            testID="compose-intro-cancel"
            variant="outline"
            onPress={onClose}
            disabled={send.isPending}
          >
            Cancel
          </Button>
        </View>
        <View className="flex-1">
          <Button
            testID="compose-intro-send"
            variant="primary"
            onPress={onSubmit}
            loading={send.isPending}
          >
            Send
          </Button>
        </View>
      </View>
    </BottomSheet>
  );
}
