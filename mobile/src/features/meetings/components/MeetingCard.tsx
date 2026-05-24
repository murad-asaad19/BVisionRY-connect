import { useState } from 'react';
import { View, Text, Pressable, ActivityIndicator } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useConfirmMeeting } from '~/features/meetings/hooks/useConfirmMeeting';
import { useDeclineMeeting } from '~/features/meetings/hooks/useDeclineMeeting';
import { useCancelMeeting } from '~/features/meetings/hooks/useCancelMeeting';
import type { MeetingState } from '~/features/meetings/services/meetings.service';
import { colors } from '~/theme/colors';
import { ICSDownloadButton } from './ICSDownloadButton';
import { MeetingPlaybookCard } from './MeetingPlaybookCard';
import { ProposeMeetingSheet } from './ProposeMeetingSheet';

// Window in which the AI playbook surface appears. Confirmed meetings get
// the prep card from 24h before the start through 1h after — the late
// boundary lets attendees pull up notes during the meeting itself but
// hides the card once the meeting has elapsed.
const PLAYBOOK_LEAD_MS = 24 * 60 * 60 * 1000;
const PLAYBOOK_TRAILING_MS = 60 * 60 * 1000;

function shouldShowPlaybook(state: MeetingState, confirmedSlot: string | null): boolean {
  if (state !== 'confirmed' || !confirmedSlot) return false;
  const start = new Date(confirmedSlot).getTime();
  if (Number.isNaN(start)) return false;
  const now = Date.now();
  return start <= now + PLAYBOOK_LEAD_MS && start >= now - PLAYBOOK_TRAILING_MS;
}

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
  /** Handle of the other participant (used for ICS summary). Falls back to a generic title when absent. */
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
 * When the proposer's TZ matches viewer's TZ (or is missing) only `primary`
 * is filled and `secondary` is omitted.
 */
function formatSlotLines(
  iso: string,
  proposerTZ: string | null | undefined,
  yourTimeLabel: string
): { primary: string; secondary: string | null } {
  const yourLocal = formatLocal(iso);
  if (!proposerTZ) return { primary: yourLocal, secondary: null };
  const proposerLocal = formatLocal(iso, proposerTZ);
  if (proposerLocal === yourLocal) return { primary: yourLocal, secondary: null };
  return { primary: proposerLocal, secondary: `${yourTimeLabel}: ${yourLocal}` };
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
  const [proposeAnotherOpen, setProposeAnotherOpen] = useState(false);
  const confirm = useConfirmMeeting(conversationId);
  const decline = useDeclineMeeting(conversationId);
  const cancel = useCancelMeeting(conversationId);

  const baseCardClass = 'bg-white border-[1.5px] border-gold rounded-xl p-4 my-2 mx-2';
  const icsSummary = otherHandle ? t('meetings.titleWith', { handle: otherHandle }) : t('meetings.title');

  if (state === 'confirmed' && confirmedSlot) {
    const lines = formatSlotLines(confirmedSlot, timezone, yourTimeLabel);
    return (
      <>
        <View testID="meeting-card-confirmed" className={baseCardClass}>
          <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-1">
            {t('meetings.statusConfirmed')}
          </Text>
          <Text
            testID="meeting-confirmed-slot"
            className="font-display-semibold text-display-sm text-navy"
          >
            {lines.primary}
          </Text>
          {lines.secondary ? (
            <Text className="font-body text-body-sm text-muted mb-1">{lines.secondary}</Text>
          ) : (
            <View className="mb-1" />
          )}
          <Text className="font-body text-body-sm text-muted">
            {t('meetings.durationLabel', { minutes: durationMinutes })}
          </Text>
          {meetingUrl && (
            <Text className="font-body text-body-sm text-navy mt-1" selectable>
              {meetingUrl}
            </Text>
          )}
          <ICSDownloadButton
            meetingId={meetingId}
            startIso={confirmedSlot}
            durationMinutes={durationMinutes}
            meetingUrl={meetingUrl}
            summary={icsSummary}
          />
        </View>
        {shouldShowPlaybook(state, confirmedSlot) && (
          <MeetingPlaybookCard meetingId={meetingId} targetName={otherHandle ?? null} />
        )}
      </>
    );
  }

  if (state === 'declined' || state === 'cancelled') {
    const statusKey = state === 'declined' ? 'meetings.statusDeclined' : 'meetings.statusCancelled';
    const testId = state === 'declined' ? 'meeting-card-declined' : 'meeting-card-cancelled';
    return (
      <>
        <View testID={testId} className="bg-white border border-border rounded-xl p-4 my-2 mx-2">
          <Text className="font-display-bold text-body-sm text-muted mb-2">{t(statusKey)}</Text>
          <Pressable
            testID="meeting-propose-another"
            onPress={() => setProposeAnotherOpen(true)}
            accessibilityRole="button"
            className="self-start bg-white border border-navy px-3 py-1.5 rounded-lg"
          >
            <Text className="font-display-semibold text-body-sm text-navy">
              {t('meetings.proposeAnother')}
            </Text>
          </Pressable>
        </View>
        <ProposeMeetingSheet
          visible={proposeAnotherOpen}
          conversationId={conversationId}
          onClose={() => setProposeAnotherOpen(false)}
          onSent={() => setProposeAnotherOpen(false)}
        />
      </>
    );
  }

  // state === 'proposed'
  return (
    <View testID="meeting-card-proposed" className={baseCardClass}>
      <Text className="font-display-bold text-body-xs text-muted uppercase tracking-wide mb-2">
        {t('meetings.durationHeader', { minutes: durationMinutes })}
      </Text>
      {meetingUrl && (
        <Text className="font-body text-body-sm text-navy mb-2" selectable>
          {meetingUrl}
        </Text>
      )}

      <View className="gap-2 mb-3">
        {slots.map((s, i) => {
          const lines = formatSlotLines(s, timezone, yourTimeLabel);
          const selected = picked === s;
          return (
            <Pressable
              key={s + i}
              testID={`meeting-slot-${i}`}
              onPress={() => isRecipient && setPicked(s)}
              disabled={!isRecipient}
              className={`px-3 py-2 rounded-lg border ${
                selected ? 'bg-navy border-navy' : 'bg-white border-border'
              }`}
            >
              <Text
                className={`font-display-semibold text-display-sm ${
                  selected ? 'text-white' : 'text-body'
                }`}
              >
                {lines.primary}
              </Text>
              {lines.secondary ? (
                <Text
                  className={`font-body text-body-sm ${
                    selected ? 'text-gold-light' : 'text-muted'
                  }`}
                >
                  {lines.secondary}
                </Text>
              ) : null}
            </Pressable>
          );
        })}
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
              <ActivityIndicator color={colors.navy} />
            ) : (
              <Text className="font-display-semibold text-body-md text-navy">
                {t('meetings.decline')}
              </Text>
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
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text className="font-display-bold text-body-md text-white">
                {t('meetings.confirm')}
              </Text>
            )}
          </Pressable>
        </View>
      )}

      {isProposer && (
        <View className="mt-2">
          <Pressable
            testID="meeting-cancel-proposal"
            onPress={() => cancel.mutate(meetingId)}
            disabled={cancel.isPending}
            accessibilityRole="button"
            className="self-start bg-white border border-border px-3 py-1.5 rounded-lg"
          >
            {cancel.isPending ? (
              <ActivityIndicator color={colors.navy} />
            ) : (
              <Text className="font-display-semibold text-body-sm text-navy">
                {t('meetings.cancelProposal')}
              </Text>
            )}
          </Pressable>
        </View>
      )}
    </View>
  );
}
