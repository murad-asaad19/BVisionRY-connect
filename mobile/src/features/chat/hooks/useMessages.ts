import { useInfiniteQuery } from '@tanstack/react-query';
import { fetchMessagesPage } from '~/features/chat/services/chat.service';
import type { MessageRow } from '~/features/chat/services/chat.service';

/**
 * Infinite-query keyed by created_at cursor. Each page is DESC by
 * created_at so an `inverted` FlatList renders newest-at-bottom natively.
 *
 * - `pages[0]` is the freshest 30 messages; subsequent pages are older.
 * - `fetchNextPage` is triggered from the list's `onEndReached` (which,
 *   with `inverted`, fires when the user scrolls UP into history).
 * - Realtime INSERTs prepend to `pages[0].rows` so they appear instantly.
 */
const PAGE_SIZE = 30;

export type MessagesPage = { rows: MessageRow[]; nextCursor: string | null };

export function useMessages(conversationId: string) {
  return useInfiniteQuery({
    queryKey: ['messages', conversationId] as const,
    enabled: !!conversationId,
    initialPageParam: null as string | null,
    queryFn: ({ pageParam }) =>
      fetchMessagesPage({
        conversationId,
        before: pageParam,
        pageSize: PAGE_SIZE,
      }),
    getNextPageParam: (lastPage: MessagesPage) => lastPage.nextCursor,
    staleTime: 15_000,
  });
}
