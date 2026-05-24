import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';
import { useFocusEffect, useIsFocused } from '@react-navigation/native';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { Bell, BellOff, ChevronDown, MoreHorizontal } from 'lucide-react-native';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useMessages } from '~/features/chat/hooks/useMessages';
import { useMessagesRealtime } from '~/features/chat/hooks/useMessagesRealtime';
import { useMarkConversationRead } from '~/features/chat/hooks/useMarkConversationRead';
import { useTypingChannel } from '~/features/chat/hooks/useTypingChannel';
import { useActiveConversationStore } from '~/features/chat/store/activeConversationStore';
import {
  useIsConversationMuted,
  useMuteConversation,
} from '~/features/chat/hooks/useMuteConversation';
import { useMeetingProposals } from '~/features/meetings/hooks/useMeetingProposals';
import { useMeetingProposalsRealtime } from '~/features/meetings/hooks/useMeetingProposalsRealtime';
import { QueryState } from '~/components/ui/QueryState';
import { TopBar } from '~/components/ui/TopBar';
import { Avatar } from '~/components/ui/Avatar';
import { colors } from '~/theme/colors';
import { MessageBubble } from './MessageBubble';
import { MessageComposer } from './MessageComposer';
import { PostMeetingPrompt } from '~/features/meetings/components/PostMeetingPrompt';
import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';
import type { MessageRow } from '~/features/chat/services/chat.service';

type ConversationRow = Database['public']['Tables']['conversations']['Row'];
type ProfileLite = Pick<
  Database['public']['Tables']['profiles']['Row'],
  'id' | 'name' | 'handle' | 'photo_url'
>;

function useConversationById(id: string) {
  return useQuery({
    queryKey: ['conversation-by-id', id],
    enabled: !!id,
    staleTime: 60_000,
    queryFn: async (): Promise<ConversationRow | null> => {
      const { data, error } = await supabase
        .from('conversations')
        .select('*')
        .eq('id', id)
        .single();
      if (error) {
        if (error.code === 'PGRST116') return null;
        throw new Error(error.message);
      }
      return data;
    },
  });
}

function usePeerProfile(id: string | null) {
  return useQuery({
    queryKey: ['profile-by-id', id],
    enabled: !!id,
    staleTime: 60_000,
    queryFn: async (): Promise<ProfileLite | null> => {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, handle, photo_url')
        .eq('id', id!)
        .single();
      if (error) {
        if (error.code === 'PGRST116') return null;
        throw new Error(error.message);
      }
      return data;
    },
  });
}

type Props = { id: string };

/**
 * Header height the keyboard offset matches. Tracks the inline header below:
 * pt-3.5 + 32 (avatar) + pb-2.5 + border = ~52. iOS uses this so the keyboard
 * doesn't cover the composer.
 */
const HEADER_HEIGHT = 56;

/**
 * Inverted FlatList: index 0 = newest = visual bottom. "At bottom" therefore
 * means contentOffset.y is near zero (the user has not scrolled up into
 * history). 50px tolerance feels right for momentum scroll overshoot.
 */
const AT_BOTTOM_THRESHOLD = 50;

export function ConversationScreen({ id }: Props) {
  const { t } = useTranslation();
  const { session } = useAuthSession();
  const myId = session?.user.id ?? '';
  const isFocused = useIsFocused();

  useMessagesRealtime(id);
  useMeetingProposalsRealtime(id);

  // Mark this conversation as the one the user is actively viewing so the
  // realtime handler can suppress the unread-count bump on inbound messages
  // (mark-read debounce will zero it shortly anyway).
  //
  // Uses `useFocusEffect` rather than `useEffect([id])` because the native
  // Stack keeps prior screens mounted underneath the top one — a plain mount
  // effect would only run when this screen first appears, leaving `activeId`
  // pointing at the wrong conversation after a back navigation (or any time
  // the user moves between sibling chat screens without unmount). With
  // `useFocusEffect`, `setActive(id)` fires every time this screen comes
  // back into focus, and the cleanup fires when it blurs.
  const setActiveConversation = useActiveConversationStore((s) => s.setActive);
  useFocusEffect(
    useCallback(() => {
      setActiveConversation(id);
      return () => setActiveConversation(null);
    }, [id, setActiveConversation])
  );

  const conversationQuery = useConversationById(id);
  const messagesQuery = useMessages(id);
  const proposalsQuery = useMeetingProposals(id);

  const markReadMutation = useMarkConversationRead();
  const mutedQuery = useIsConversationMuted(id);
  const muteMutation = useMuteConversation(id);
  const { isOtherTyping, sendTyping, sendStoppedTyping } = useTypingChannel(
    id,
    myId || undefined
  );

  const peerId = useMemo(() => {
    const conv = conversationQuery.data;
    if (!conv || !myId) return null;
    return conv.participant_a_id === myId ? conv.participant_b_id : conv.participant_a_id;
  }, [conversationQuery.data, myId]);

  const peerQuery = usePeerProfile(peerId);
  const peer = peerQuery.data;

  const proposalsById = useMemo(() => {
    const map = new Map<string, NonNullable<typeof proposalsQuery.data>[number]>();
    (proposalsQuery.data ?? []).forEach((p) => map.set(p.id, p));
    return map;
  }, [proposalsQuery.data]);

  // Flatten pages into a single array. Each page is already DESC by created_at,
  // so concatenating pages 0..N yields the order an inverted FlatList wants
  // (newest first, oldest last).
  const messages = useMemo<MessageRow[]>(
    () => messagesQuery.data?.pages.flatMap((p) => p.rows) ?? [],
    [messagesQuery.data]
  );

  // Track whether the user is parked at the most recent message. With an
  // inverted list, "at bottom" == contentOffset.y near 0.
  const [isAtBottom, setIsAtBottom] = useState(true);
  const listRef = useRef<FlatList<MessageRow>>(null);

  const onScroll = useCallback((e: NativeSyntheticEvent<NativeScrollEvent>) => {
    const y = e.nativeEvent.contentOffset.y;
    setIsAtBottom(y < AT_BOTTOM_THRESHOLD);
  }, []);

  // When a new message arrives:
  //  - if the user is at the bottom, auto-scroll to keep them anchored;
  //  - otherwise, leave them parked in history and show the "new messages"
  //    pill so they can opt in.
  const newestId = messages[0]?.id;
  const newestIdRef = useRef<string | null>(null);
  useEffect(() => {
    if (!newestId) return;
    if (newestIdRef.current === newestId) return;
    const isFirstLoad = newestIdRef.current === null;
    newestIdRef.current = newestId;
    if (isFirstLoad || isAtBottom) {
      requestAnimationFrame(() => listRef.current?.scrollToOffset({ offset: 0, animated: !isFirstLoad }));
    }
  }, [newestId, isAtBottom]);

  // Mark-read debounce: fires once on screen focus + once 1.5s after the
  // most recent message arrives while still focused. Gating on `isFocused`
  // avoids burning the RPC quota on background screens.
  useEffect(() => {
    if (!id || !myId || !isFocused) return;
    const handle = setTimeout(() => {
      markReadMutation.mutate(id);
    }, 1500);
    // The dependency on `newestId` makes this re-trigger when a new message
    // comes in; the dependency on `isFocused` makes it trigger on focus
    // (after the initial mount).
    return () => clearTimeout(handle);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, myId, isFocused, newestId]);

  // Clear the peer's "typing..." indicator when leaving the screen.
  useEffect(() => {
    if (!isFocused) sendStoppedTyping();
  }, [isFocused, sendStoppedTyping]);

  const isMuted = mutedQuery.data === true;

  // Destructure so the callback identity is stable across renders that
  // produce a new `messagesQuery` object reference but the same paging
  // state — otherwise the FlatList re-binds onEndReached on every render.
  const { hasNextPage, isFetchingNextPage, fetchNextPage } = messagesQuery;
  const onEndReached = useCallback(() => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

  const renderItem = useCallback(
    ({ item }: { item: MessageRow }) => {
      const proposal = item.meeting_proposal_id
        ? (proposalsById.get(item.meeting_proposal_id) ?? null)
        : null;
      return (
        <MessageBubble
          message={item}
          isMine={item.sender_id === myId}
          proposal={proposal}
          conversationId={id}
          myId={myId}
          peerHandle={peer?.handle ?? null}
        />
      );
    },
    [proposalsById, myId, id, peer?.handle]
  );

  const scrollToBottom = useCallback(() => {
    listRef.current?.scrollToOffset({ offset: 0, animated: true });
  }, []);

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={HEADER_HEIGHT}
    >
      <View className="flex-1 bg-surface">
        <View className="flex-1 w-full max-w-2xl mx-auto">
          <TopBar
            back
            leading={
              <Avatar
                name={peer?.name ?? '?'}
                photoUrl={peer?.photo_url ?? null}
                size={32}
              />
            }
            title={peer?.name ?? '...'}
            subtitle={peer?.handle ? `@${peer.handle}` : undefined}
            titleTestID="conversation-peer-name"
            actions={[
              {
                testID: 'conversation-mute-toggle',
                icon: isMuted ? (
                  <BellOff size={18} color={colors.navy} />
                ) : (
                  <Bell size={18} color={colors.navy} />
                ),
                onPress: () => muteMutation.mutate(!isMuted),
                label: isMuted ? t('chat.unmute') : t('chat.mute'),
              },
              {
                testID: 'conversation-more',
                icon: <MoreHorizontal size={18} color={colors.navy} />,
                onPress: () => {
                  // Reserved for a future overflow menu (block, report, etc.).
                  // The audit (P0-2) called for the affordance to exist; the
                  // sheet contents are out of scope for this pass.
                },
                label: t('chat.messageActionsMore'),
              },
            ]}
          />

          <QueryState
            query={{
              isLoading: messagesQuery.isLoading,
              isError: messagesQuery.isError,
              error: messagesQuery.error,
              data: messagesQuery.isSuccess ? messages : undefined,
              refetch: () => {
                messagesQuery.refetch();
              },
            }}
            isEmpty={(data) => data.length === 0}
            emptyFallback={
              <View className="flex-1 items-center justify-center px-6">
                <Text className="font-body text-body-md text-muted text-center">
                  {t('chat.noMessages')}
                </Text>
              </View>
            }
          >
            {(rows) => (
              <View className="flex-1">
                <FlatList
                  ref={listRef}
                  testID="messages-list"
                  data={rows}
                  inverted
                  keyExtractor={(m) => m.id}
                  contentContainerStyle={{ paddingHorizontal: 16, paddingVertical: 8 }}
                  renderItem={renderItem}
                  onScroll={onScroll}
                  scrollEventThrottle={16}
                  onEndReached={onEndReached}
                  onEndReachedThreshold={0.5}
                />
                {!isAtBottom && (
                  <Pressable
                    testID="conversation-scroll-to-bottom"
                    accessibilityRole="button"
                    accessibilityLabel={t('chat.newMessages')}
                    onPress={scrollToBottom}
                    className="absolute bottom-2 self-center bg-navy rounded-full px-4 py-1.5 flex-row items-center gap-1"
                  >
                    <Text className="font-display-bold text-body-md text-white">
                      {t('chat.newMessages')}
                    </Text>
                    <ChevronDown size={14} color={colors.white} />
                  </Pressable>
                )}
              </View>
            )}
          </QueryState>

          {isOtherTyping && (
            <View testID="conversation-typing-indicator" className="px-gutter py-1">
              <Text className="font-body text-body-sm text-muted italic">
                {peer?.name ?? '...'} {t('chat.typing')}
              </Text>
            </View>
          )}

          <MessageComposer
            conversationId={id}
            onTyping={sendTyping}
            onStoppedTyping={sendStoppedTyping}
          />
          <PostMeetingPrompt conversationId={id} />
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}
