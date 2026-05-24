import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { InfiniteData } from '@tanstack/react-query';
import { sendMessage } from '~/features/chat/services/chat.service';
import { useAuthSession } from '~/features/auth/SessionContext';
import type { MessageRow } from '~/features/chat/services/chat.service';
import type { MessagesPage } from '~/features/chat/hooks/useMessages';

type Variables = { body: string; tempId: string };
type Ctx = { tempId: string; previous: InfiniteData<MessagesPage, string | null> | undefined };

/**
 * Generates a v4 UUID for use as a message id. Hermes (RN 0.79+) provides
 * `crypto.randomUUID`; the RFC 4122 v4 fallback covers jest/node environments
 * and very old JSCore where it is missing. The fallback MUST yield a valid
 * UUID — `messages.id` is a `uuid` column, and a non-UUID id triggers
 * Postgres 22P02 on INSERT.
 *
 * Exported so callers can pre-generate an id and pass it through the
 * mutation. The same id is used for the optimistic row, the server INSERT
 * (`messages.id` column), and the realtime broadcast — so dedup-by-id is
 * trivial everywhere.
 */
export function newMessageId(): string {
  const fromCrypto = globalThis.crypto?.randomUUID?.();
  if (fromCrypto) return fromCrypto;
  // RFC 4122 v4 fallback (rare path: very old JSCore / non-Hermes test envs).
  const bytes = new Uint8Array(16);
  for (let i = 0; i < 16; i += 1) bytes[i] = Math.floor(Math.random() * 256);
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function makeOptimisticRow(params: {
  id: string;
  conversationId: string;
  senderId: string;
  body: string;
}): MessageRow {
  return {
    id: params.id,
    conversation_id: params.conversationId,
    sender_id: params.senderId,
    body: params.body,
    kind: 'text',
    created_at: new Date().toISOString(),
    edited_at: null,
    deleted_at: null,
    media_path: null,
    media_duration_ms: null,
    media_size_bytes: null,
    meeting_proposal_id: null,
    transcript: null,
    transcript_status: null,
  };
}

/**
 * Optimistic + rolled-back send.
 *
 * - Caller generates a `tempId` via `newMessageId()` and passes it alongside
 *   `body`. The mutationFn forwards the id to `sendMessage({ id, ... })`
 *   so the server INSERT uses the same UUID — temp row, server row, and
 *   realtime broadcast share one id (clean dedup everywhere).
 * - `onMutate` inserts the temp row into page 0.
 * - `onError` rolls back to the cache snapshot taken in onMutate.
 * - `onSuccess` swaps the temp row for the server row in page 0. Realtime
 *   may have already inserted it before onSuccess fires; in that case the
 *   filter-by-tempId is a no-op (id equality means realtime already
 *   replaced it). Either way the row is present exactly once at the end.
 */
export function useSendMessage(conversationId: string) {
  const qc = useQueryClient();
  const { session } = useAuthSession();
  const senderId = session?.user.id;

  return useMutation<MessageRow, Error, Variables, Ctx>({
    mutationFn: ({ body, tempId }) => {
      if (!senderId) throw new Error('Not authenticated');
      return sendMessage({ id: tempId, conversationId, senderId, body });
    },
    onMutate: async ({ body, tempId }) => {
      const fallback: Ctx = { tempId, previous: undefined };
      if (!senderId) return fallback;
      await qc.cancelQueries({ queryKey: ['messages', conversationId] });
      const previous = qc.getQueryData<InfiniteData<MessagesPage, string | null>>([
        'messages',
        conversationId,
      ]);
      const optimistic = makeOptimisticRow({ id: tempId, conversationId, senderId, body });
      qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
        ['messages', conversationId],
        (prev) => {
          if (!prev || prev.pages.length === 0) {
            return {
              pages: [{ rows: [optimistic], nextCursor: null }],
              pageParams: [null],
            };
          }
          const [first, ...rest] = prev.pages;
          return {
            ...prev,
            pages: [{ ...first!, rows: [optimistic, ...first!.rows] }, ...rest],
          };
        }
      );
      return { tempId, previous };
    },
    onError: (_err, _vars, ctx) => {
      if (!ctx) return;
      qc.setQueryData(['messages', conversationId], ctx.previous);
    },
    onSuccess: (serverRow, vars, ctx) => {
      qc.setQueryData<InfiniteData<MessagesPage, string | null>>(
        ['messages', conversationId],
        (prev) => {
          if (!prev || prev.pages.length === 0) return prev;
          const [first, ...rest] = prev.pages;
          if (!first) return prev;
          const tempId = ctx?.tempId ?? vars.tempId;
          let rows = first.rows;
          if (tempId) rows = rows.filter((m) => m.id !== tempId);
          if (!rows.some((m) => m.id === serverRow.id)) rows = [serverRow, ...rows];
          return { ...prev, pages: [{ ...first, rows }, ...rest] };
        }
      );
      qc.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}
