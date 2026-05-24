import { useEffect } from 'react';
import type { InfiniteData } from '@tanstack/react-query';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '~/lib/supabase/client';
import { useAuthSession } from '~/features/auth/SessionContext';
import { useActiveConversationStore } from '~/features/chat/store/activeConversationStore';
import type { MessageRow } from '~/features/chat/services/chat.service';
import type { MessagesPage } from '~/features/chat/hooks/useMessages';
import type { ConversationOverviewRow } from '~/features/chat/services/chat.service';

/**
 * Subscribes to INSERT + UPDATE on public.messages for one conversation.
 *
 * - INSERT prepends the new row onto `pages[0]` of the infinite messages
 *   cache (dedup by id), and bumps the conversation to the top of the
 *   chats overview cache in-place (no broad invalidation, which would
 *   re-issue the overview RPC).
 * - UPDATE (edits / soft-deletes) replaces the cached row in place across
 *   all pages. The migration sets `replica identity full` on
 *   public.messages so UPDATE payloads carry every column.
 *
 * Cache scoping: the chats-overview key shape is `['conversations', userId]`
 * so we filter the broad `setQueriesData` by the current user's id to avoid
 * bleeding into other accounts' caches (matters when an account switches
 * without the React Query client being cleared, or in dev fast-refresh).
 *
 * Unread bump: skipped when the user has this conversation actively open on
 * screen — `mark_conversation_read` will zero the badge on the next debounce
 * tick anyway, and the visual flicker (count appears, then disappears) is
 * jarring. We read the active id from the Zustand store via `getState()` in
 * the handler so the channel callback doesn't subscribe to re-renders.
 */
export function useMessagesRealtime(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const userId = session?.user.id;

  useEffect(() => {
    if (!conversationId) return;

    const channel = supabase
      // Namespaced to match the chat:typing:<id> channel for consistency.
      .channel(`chat:messages:${conversationId}`)
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

          // 1) Prepend to page 0 of the infinite messages cache. Sort by
          //    created_at DESC after insert as a defence against out-of-order
          //    realtime delivery.
          qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
            ['messages', conversationId],
            (prev) => {
              if (!prev) return prev;
              const [firstPage, ...rest] = prev.pages;
              if (!firstPage) return prev;
              if (firstPage.rows.some((m) => m.id === row.id)) return prev;
              const rows = [row, ...firstPage.rows].sort((a, b) =>
                a.created_at < b.created_at ? 1 : -1
              );
              return {
                ...prev,
                pages: [{ ...firstPage, rows }, ...rest],
              };
            }
          );

          // 2) Mutate the chats overview cache in-place. Bump this convo
          //    to the top and refresh its preview + last_message_at +
          //    unread_count. Scoped by userId via the query key filter so
          //    we don't bleed into other accounts' caches.
          const activeId = useActiveConversationStore.getState().activeId;
          const suppressUnreadBump = activeId === conversationId;
          qc.setQueriesData<ConversationOverviewRow[]>(
            { queryKey: ['conversations', userId] },
            (prev) => {
              if (!prev) return prev;
              const idx = prev.findIndex((r) => r.conversation_id === conversationId);
              if (idx === -1) return prev;
              const existing = prev[idx]!;
              // Bump unread only when: (a) message is FROM the peer, AND
              // (b) the conversation isn't the one currently on-screen.
              // conversation-unread is invalidated below as a backstop.
              const fromPeer = row.sender_id != null && row.sender_id === existing.peer_id;
              const shouldBump = fromPeer && !suppressUnreadBump;
              const updated: ConversationOverviewRow = {
                ...existing,
                last_message_body: row.body,
                last_message_kind: row.kind,
                last_message_at: row.created_at,
                unread_count: shouldBump ? existing.unread_count + 1 : existing.unread_count,
              };
              const next = [updated, ...prev.slice(0, idx), ...prev.slice(idx + 1)];
              return next;
            }
          );

          qc.invalidateQueries({ queryKey: ['conversation-unread', userId] });
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
          qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
            ['messages', conversationId],
            (prev) => {
              if (!prev) return prev;
              return {
                ...prev,
                pages: prev.pages.map((page) => ({
                  ...page,
                  rows: page.rows.map((m) => (m.id === row.id ? row : m)),
                })),
              };
            }
          );

          // If the edit/soft-delete touched the most recent message in this
          // conversation, the chats overview preview is stale. Patch in
          // place when we can detect it cheaply by comparing the updated
          // row's `created_at` against the cached `last_message_at` — this
          // works because the migration sets `replica identity full` on
          // public.messages so UPDATE payloads include every column, not
          // just the changed ones. Otherwise fall back to a targeted
          // invalidation. UPDATEs are rare enough that the round-trip cost
          // of the invalidate is acceptable. Scoped by userId, same reason
          // as the INSERT branch.
          qc.setQueriesData<ConversationOverviewRow[]>(
            { queryKey: ['conversations', userId] },
            (prev) => {
              if (!prev) return prev;
              const idx = prev.findIndex((r) => r.conversation_id === conversationId);
              if (idx === -1) return prev;
              const existing = prev[idx]!;
              if (existing.last_message_at !== row.created_at) return prev;
              const updated: ConversationOverviewRow = {
                ...existing,
                last_message_body: row.deleted_at ? null : row.body,
                last_message_kind: row.kind,
              };
              return [...prev.slice(0, idx), updated, ...prev.slice(idx + 1)];
            }
          );
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId, qc, userId]);
}
