import { useCallback, useEffect, useRef, useState } from 'react';
import { supabase } from '~/lib/supabase/client';
import type { RealtimeChannel } from '@supabase/supabase-js';

/**
 * Realtime broadcast channel for typing indicators in a conversation.
 *
 * - Subscribes to `chat:typing:{conversationId}` (namespaced under `chat:`
 *   so future per-feature channels won't collide).
 * - Sets `isOtherTyping=true` when a peer broadcasts typing; clears after
 *   3s of silence locally, or immediately when the peer broadcasts
 *   `stopped_typing` (which is sent on blur from the composer side).
 * - `sendTyping()` is throttled to once per 1s.
 * - `sendStoppedTyping()` is meant to be called when the local user blurs
 *   the conversation (component unmount, screen unfocus, app background)
 *   so the peer's "typing..." indicator clears promptly.
 *
 * No DB writes — pure Supabase Realtime broadcast.
 */
export function useTypingChannel(conversationId: string, myUserId: string | undefined) {
  const [isOtherTyping, setIsOtherTyping] = useState(false);
  const lastSentRef = useRef(0);
  const timerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const channelRef = useRef<RealtimeChannel | undefined>(undefined);

  useEffect(() => {
    if (!conversationId || !myUserId) return;

    const channel = supabase.channel(`chat:typing:${conversationId}`, {
      config: { broadcast: { self: false } },
    });

    channel.on('broadcast', { event: 'typing' }, (msg) => {
      const payloadUserId = (msg as { payload?: { user_id?: string } }).payload?.user_id;
      if (payloadUserId && payloadUserId !== myUserId) {
        setIsOtherTyping(true);
        if (timerRef.current) clearTimeout(timerRef.current);
        timerRef.current = setTimeout(() => setIsOtherTyping(false), 3000);
      }
    });

    channel.on('broadcast', { event: 'stopped_typing' }, (msg) => {
      const payloadUserId = (msg as { payload?: { user_id?: string } }).payload?.user_id;
      if (payloadUserId && payloadUserId !== myUserId) {
        if (timerRef.current) {
          clearTimeout(timerRef.current);
          timerRef.current = undefined;
        }
        setIsOtherTyping(false);
      }
    });

    channel.subscribe();
    channelRef.current = channel;

    return () => {
      supabase.removeChannel(channel);
      if (timerRef.current) clearTimeout(timerRef.current);
      channelRef.current = undefined;
    };
  }, [conversationId, myUserId]);

  const sendTyping = useCallback(() => {
    const channel = channelRef.current;
    if (!channel || !myUserId) return;
    const now = Date.now();
    if (now - lastSentRef.current < 1000) return;
    lastSentRef.current = now;
    channel.send({
      type: 'broadcast',
      event: 'typing',
      payload: { user_id: myUserId },
    });
  }, [myUserId]);

  const sendStoppedTyping = useCallback(() => {
    const channel = channelRef.current;
    if (!channel || !myUserId) return;
    // Reset the throttle so any subsequent typing send fires immediately.
    lastSentRef.current = 0;
    channel.send({
      type: 'broadcast',
      event: 'stopped_typing',
      payload: { user_id: myUserId },
    });
  }, [myUserId]);

  return { isOtherTyping, sendTyping, sendStoppedTyping };
}
