import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import type { MessageRow } from '~/features/chat/services/chat.service';

/**
 * Subscribes to INSERT + UPDATE events on public.messages filtered by conversation_id.
 *
 * - INSERT pushes new rows into the ['messages', conversationId] cache, dedup by id.
 * - UPDATE (edits + soft-deletes) replaces the cached row in place.
 * - Cleans up the channel on unmount.
 */
export function useMessagesRealtime(conversationId: string) {
  const qc = useQueryClient();

  useEffect(() => {
    if (!conversationId) return;

    const channel = supabase
      .channel(`messages:${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${conversationId}`,
        },
        (payload) => {
          const row = payload.new as MessageRow;
          qc.setQueryData<MessageRow[]>(['messages', conversationId], (prev) => {
            if (!prev) return [row];
            if (prev.some((m) => m.id === row.id)) return prev;
            return [...prev, row];
          });
          qc.invalidateQueries({ queryKey: ['conversations'] });
          qc.invalidateQueries({ queryKey: ['conversation-unread'] });
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${conversationId}`,
        },
        (payload) => {
          const row = payload.new as MessageRow;
          qc.setQueryData<MessageRow[]>(['messages', conversationId], (prev) => {
            if (!prev) return prev;
            return prev.map((m) => (m.id === row.id ? row : m));
          });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId, qc]);
}
