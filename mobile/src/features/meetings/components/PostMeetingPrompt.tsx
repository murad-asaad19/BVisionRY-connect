import { useState } from 'react';
import { View, Text, Modal } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { Button } from '~/components/ui/Button';
import { PostConnectionReview } from '~/features/meetings/components/PostConnectionReview';
import { useAuthSession } from '~/features/auth/SessionContext';
import { fetchPendingMeetingReviews } from '~/features/meetings/services/meetings.service';

type Props = { conversationId: string };

/**
 * Full-screen prompt (mockup G2): "Did this meeting happen?" with three
 * outcomes — happened / rescheduled / no-show — plus a 48-hour fallback note.
 * The G3 review surface only opens when the user picks "Yes — it happened";
 * the other branches close the prompt without writing a review (server can
 * follow up async).
 */
export function PostMeetingPrompt({ conversationId }: Props) {
  const { session } = useAuthSession();
  const userId = session?.user.id;
  const [showPrompt, setShowPrompt] = useState(true);
  const [reviewing, setReviewing] = useState(false);

  const pending = useQuery({
    queryKey: ['pending-meeting-reviews', conversationId, userId],
    enabled: !!userId,
    queryFn: () => fetchPendingMeetingReviews(userId!, conversationId),
    staleTime: 30_000,
  });

  const meeting = pending.data?.[0];

  if (!meeting) return null;

  const visible = showPrompt && !reviewing;

  return (
    <>
      <Modal visible={visible} animationType="fade" transparent={false}>
        <View testID="post-meeting-prompt" className="flex-1 bg-surface px-6 pt-20 pb-6">
          <Text className="font-display-bold text-[20px] text-navy text-center mb-2">
            Did this meeting happen?
          </Text>
          <Text className="font-body text-[12px] text-muted text-center mb-6">
            Tell us so we can improve your matches.
          </Text>

          <View className="gap-3">
            <Button
              testID="post-meeting-yes"
              variant="primary"
              onPress={() => {
                setShowPrompt(false);
                setReviewing(true);
              }}
            >
              Yes — it happened
            </Button>
            <Button
              testID="post-meeting-reschedule"
              variant="outline"
              onPress={() => setShowPrompt(false)}
            >
              Rescheduled to a new time
            </Button>
            <Button
              testID="post-meeting-no-show"
              variant="outline"
              onPress={() => setShowPrompt(false)}
            >
              No — they didn&apos;t show
            </Button>
          </View>

          <Text className="font-body text-[10px] text-muted text-center mt-6 leading-snug">
            If we don&apos;t hear back within 48 hours, we&apos;ll skip this prompt and ask later.
          </Text>
        </View>
      </Modal>

      <PostConnectionReview
        visible={reviewing}
        onClose={() => setReviewing(false)}
        meetingId={meeting.id}
      />
    </>
  );
}
