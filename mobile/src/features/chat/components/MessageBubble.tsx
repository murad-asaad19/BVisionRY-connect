import { useState } from 'react';
import { View, Text, Pressable, TextInput, Alert, ActivityIndicator } from 'react-native';
import { useTranslation } from 'react-i18next';
import { MeetingCard } from '~/features/meetings/components/MeetingCard';
import { ImageMessageBubble } from '~/features/media/components/ImageMessageBubble';
import { VoiceMessageBubble } from '~/features/media/components/VoiceMessageBubble';
import { useEditMessage } from '~/features/chat/hooks/useEditMessage';
import { useDeleteMessage } from '~/features/chat/hooks/useDeleteMessage';
import type { Database } from '~/lib/supabase/types.gen';

type MessageRow = Database['public']['Tables']['messages']['Row'];
type ProposalRow = Database['public']['Tables']['meeting_proposals']['Row'];

const EDIT_WINDOW_MS = 15 * 60 * 1000;

type Props = {
  message: Pick<
    MessageRow,
    | 'id'
    | 'body'
    | 'kind'
    | 'meeting_proposal_id'
    | 'sender_id'
    | 'media_path'
    | 'media_duration_ms'
    | 'created_at'
    | 'edited_at'
    | 'deleted_at'
    | 'transcript'
    | 'transcript_status'
  >;
  isMine: boolean;
  proposal: ProposalRow | null; // resolved by parent when kind='meeting'
  conversationId: string;
  myId: string;
  /** Handle of the other participant — threaded into MeetingCard for ICS summary. */
  peerHandle?: string | null;
};

export function MessageBubble({
  message,
  isMine,
  proposal,
  conversationId,
  myId,
  peerHandle,
}: Props) {
  const { t } = useTranslation();
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState<string>(message.body ?? '');

  const editMutation = useEditMessage(conversationId);
  const deleteMutation = useDeleteMessage(conversationId);

  // Deleted tombstone (applies to any kind)
  if (message.deleted_at) {
    return (
      <View
        testID={isMine ? 'message-bubble-mine' : 'message-bubble-theirs'}
        className={`max-w-[80%] px-3.5 py-2 rounded-2xl my-1 bg-white border border-border ${
          isMine ? 'self-end rounded-br-sm' : 'self-start rounded-bl-sm'
        }`}
      >
        <Text
          className="font-body text-[12px] text-muted italic"
          testID="message-deleted-placeholder"
        >
          {t('chat.deletedPlaceholder')}
        </Text>
      </View>
    );
  }

  if (message.kind === 'meeting' && proposal) {
    return (
      <MeetingCard
        conversationId={conversationId}
        myId={myId}
        proposedById={proposal.proposed_by_id}
        meetingId={proposal.id}
        slots={proposal.slots as string[]}
        confirmedSlot={proposal.confirmed_slot}
        durationMinutes={proposal.duration_minutes}
        meetingUrl={proposal.meeting_url}
        state={proposal.state}
        timezone={proposal.timezone}
        otherHandle={peerHandle ?? null}
      />
    );
  }

  if (message.kind === 'image' && message.media_path) {
    return <ImageMessageBubble mediaPath={message.media_path} isMine={isMine} />;
  }

  if (message.kind === 'voice' && message.media_path && message.media_duration_ms != null) {
    return (
      <VoiceMessageBubble
        mediaPath={message.media_path}
        durationMs={message.media_duration_ms}
        isMine={isMine}
        transcript={message.transcript ?? null}
        transcriptStatus={message.transcript_status ?? null}
      />
    );
  }

  const canEdit =
    isMine &&
    message.kind === 'text' &&
    !message.deleted_at &&
    Date.now() - new Date(message.created_at).getTime() < EDIT_WINDOW_MS;
  const canDelete = isMine;

  const openMenu = () => {
    if (!isMine) return;
    const actions: {
      text: string;
      style?: 'default' | 'destructive' | 'cancel';
      onPress?: () => void;
    }[] = [];
    if (canEdit) {
      actions.push({
        text: t('chat.edit'),
        onPress: () => {
          setDraft(message.body ?? '');
          setEditing(true);
        },
      });
    }
    if (canDelete) {
      actions.push({
        text: t('chat.delete'),
        style: 'destructive',
        onPress: () => {
          deleteMutation.mutate(message.id);
        },
      });
    }
    actions.push({ text: t('chat.cancel'), style: 'cancel' });
    Alert.alert('', '', actions);
  };

  const submitEdit = async () => {
    const trimmed = draft.trim();
    if (!trimmed || trimmed === message.body) {
      setEditing(false);
      return;
    }
    try {
      await editMutation.mutateAsync({ id: message.id, body: trimmed });
      setEditing(false);
    } catch {
      // surface in UI via mutation error if needed; keep editor open
    }
  };

  if (editing) {
    return (
      <View
        testID={isMine ? 'message-bubble-mine' : 'message-bubble-theirs'}
        className={`max-w-[80%] px-3 py-2 rounded-2xl my-1 ${
          isMine
            ? 'self-end bg-navy rounded-br-sm'
            : 'self-start bg-white border border-border rounded-bl-sm'
        }`}
      >
        <TextInput
          testID="message-edit-input"
          value={draft}
          onChangeText={setDraft}
          multiline
          maxLength={4000}
          className={`font-body text-[13px] ${isMine ? 'text-white' : 'text-body'}`}
        />
        <View className="flex-row justify-end mt-1 gap-3">
          <Pressable testID="message-edit-cancel" onPress={() => setEditing(false)}>
            <Text className={`text-[11px] ${isMine ? 'text-gold-light' : 'text-muted'}`}>
              {t('chat.cancel')}
            </Text>
          </Pressable>
          <Pressable
            testID="message-edit-save"
            onPress={submitEdit}
            disabled={editMutation.isPending}
          >
            {editMutation.isPending ? (
              <ActivityIndicator color={isMine ? '#ffffff' : '#0f3460'} />
            ) : (
              <Text
                className={`font-display-bold text-[11px] ${isMine ? 'text-gold' : 'text-navy'}`}
              >
                {t('chat.save')}
              </Text>
            )}
          </Pressable>
        </View>
      </View>
    );
  }

  return (
    <Pressable
      onLongPress={openMenu}
      testID={isMine ? 'message-bubble-mine' : 'message-bubble-theirs'}
      className={`max-w-[80%] px-3.5 py-2 rounded-2xl my-1 ${
        isMine
          ? 'self-end bg-navy rounded-br-sm'
          : 'self-start bg-white border border-border rounded-bl-sm'
      }`}
    >
      <Text className={`font-body text-[13px] ${isMine ? 'text-white' : 'text-body'}`}>
        {message.body ?? ''}
      </Text>
      {message.edited_at && (
        <Text
          className={`font-body text-[10px] mt-0.5 ${isMine ? 'text-gold-light' : 'text-muted'}`}
          testID="message-edited-suffix"
        >
          ({t('chat.edited')})
        </Text>
      )}
    </Pressable>
  );
}
