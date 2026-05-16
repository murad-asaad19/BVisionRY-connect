import { useState } from 'react';
import { View, Text, Pressable, ActivityIndicator } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useConfirmMeeting } from '~/features/meetings/hooks/useConfirmMeeting';
import { useDeclineMeeting } from '~/features/meetings/hooks/useDeclineMeeting';
import type { MeetingState } from '~/features/meetings/services/meetings.service';
import { ICSDownloadButton } from './ICSDownloadButton';

type Props = {
  conversationId: string;
  myId: string;
  proposedById: string | null;
  meetingId: string;
  slots: string[];
  confirmedSlot: string | null;
  durationMinutes: number;
  meetingUrl: string | null;
  state: MeetingState;
  /** IANA timezone of the proposer, e.g. `America/Los_Angeles`. */
  timezone?: string | null;
  /** Handle of the other participant (used for ICS summary). Falls back to "peer" when absent. */
  otherHandle?: string | null;
};

function formatLocal(iso: string, timeZone?: string): string {
  const d = new Date(iso);
  if (isNaN(d.getTime())) return iso;
  try {
    return new Intl.DateTimeFormat(undefined, {
      timeZone,
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      timeZoneName: 'short',
    }).format(d);
  } catch {
    // Invalid timezone — fall back to local without timeZone option.
    return new Intl.DateTimeFormat(undefined, {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      timeZoneName: 'short',
    }).format(d);
  }
}

/**
 * Render a slot with both the proposer's timezone AND the recipient's local time.
 * When the proposer's TZ matches viewer's TZ (or is missing) only the viewer's time is shown.
 */
function formatSlotWithTZ(
  iso: string,
  proposerTZ: string | null | undefined,
  yourTimeLabel: string
): string {
  const yourLocal = formatLocal(iso);
  if (!proposerTZ) return yourLocal;
  const proposerLocal = formatLocal(iso, proposerTZ);
  if (proposerLocal === yourLocal) return yourLocal;
  return `${proposerLocal}\n(${yourTimeLabel}: ${yourLocal})`;
}

export function MeetingCard({
  conversationId,
  myId,
  proposedById,
  meetingId,
  slots,
  confirmedSlot,
  durationMinutes,
  meetingUrl,
  state,
  timezone,
  otherHandle,
}: Props) {
  const { t } = useTranslation();
  const yourTimeLabel = t('meetings.yourTime');
  const isProposer = proposedById === myId;
  const isRecipient = !isProposer;
  const [picked, setPicked] = useState<string | null>(null);
  const confirm = useConfirmMeeting(conversationId);
  const decline = useDeclineMeeting(conversationId);

  const baseCardClass = 'bg-white border-[1.5px] border-gold rounded-xl p-4 my-2 mx-2';

  if (state === 'confirmed' && confirmedSlot) {
    return (
      <View testID="meeting-card-confirmed" className={baseCardClass}>
        <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-1">
          Meeting confirmed
        </Text>
        <Text
          testID="meeting-confirmed-slot"
          className="font-display-bold text-[14px] text-navy mb-1"
        >
          {formatSlotWithTZ(confirmedSlot, timezone, yourTimeLabel)}
        </Text>
        <Text className="font-body text-[11px] text-muted">Duration: {durationMinutes} min</Text>
        {meetingUrl && (
          <Text className="font-body text-[11px] text-navy mt-1" selectable>
            {meetingUrl}
          </Text>
        )}
        <ICSDownloadButton
          meetingId={meetingId}
          startIso={confirmedSlot}
          durationMinutes={durationMinutes}
          meetingUrl={meetingUrl}
          summary={otherHandle ? `Meeting with @${otherHandle}` : 'Meeting'}
        />
      </View>
    );
  }

  if (state === 'declined') {
    return (
      <View
        testID="meeting-card-declined"
        className="bg-white border border-border rounded-xl p-4 my-2 mx-2"
      >
        <Text className="font-display-bold text-[11px] text-muted">Meeting declined</Text>
      </View>
    );
  }

  if (state === 'cancelled') {
    return (
      <View
        testID="meeting-card-cancelled"
        className="bg-white border border-border rounded-xl p-4 my-2 mx-2"
      >
        <Text className="font-display-bold text-[11px] text-muted">Meeting cancelled</Text>
      </View>
    );
  }

  // state === 'proposed'
  return (
    <View testID="meeting-card-proposed" className={baseCardClass}>
      <Text className="font-display-bold text-[10px] text-muted uppercase tracking-wide mb-2">
        Meeting proposed · {durationMinutes} min
      </Text>
      {meetingUrl && (
        <Text className="font-body text-[11px] text-navy mb-2" selectable>
          {meetingUrl}
        </Text>
      )}

      <View className="gap-2 mb-3">
        {slots.map((s, i) => (
          <Pressable
            key={s + i}
            testID={`meeting-slot-${i}`}
            onPress={() => isRecipient && setPicked(s)}
            disabled={!isRecipient}
            className={`px-3 py-2 rounded-lg border ${
              picked === s ? 'bg-navy border-navy' : 'bg-white border-border'
            }`}
          >
            <Text className={`font-body text-[12px] ${picked === s ? 'text-white' : 'text-body'}`}>
              {formatSlotWithTZ(s, timezone, yourTimeLabel)}
            </Text>
          </Pressable>
        ))}
      </View>

      {isRecipient && (
        <View className="flex-row gap-2 mt-1">
          <Pressable
            testID="meeting-decline"
            onPress={() => decline.mutate(meetingId)}
            disabled={decline.isPending}
            className="flex-1 bg-white border border-border px-3 py-2 rounded-lg items-center"
          >
            {decline.isPending ? (
              <ActivityIndicator color="#0f3460" />
            ) : (
              <Text className="font-display-semibold text-[12px] text-navy">Decline</Text>
            )}
          </Pressable>
          <Pressable
            testID="meeting-confirm"
            onPress={() => picked && confirm.mutate({ meetingId, slot: picked })}
            disabled={!picked || confirm.isPending}
            className={`flex-1 px-3 py-2 rounded-lg items-center ${
              !picked || confirm.isPending ? 'bg-slate-300' : 'bg-navy'
            }`}
          >
            {confirm.isPending ? (
              <ActivityIndicator color="#ffffff" />
            ) : (
              <Text className="font-display-bold text-[12px] text-white">Confirm</Text>
            )}
          </Pressable>
        </View>
      )}
    </View>
  );
}
