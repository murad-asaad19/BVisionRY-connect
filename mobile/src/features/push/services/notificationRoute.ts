// Maps an incoming push message to the in-app route the user should land on
// when they tap it (or when we render an in-app toast for a foreground push).
//
// Two payload shapes are supported:
//
// 1. Modern, structured (`data.kind` + `data.entity_id` + optional
//    `data.conversation_id`). Emitted by `public.dispatch_push` from
//    20260606150000_dispatch_push_payload.sql onwards. Lets the client route
//    deterministically without parsing server-rendered strings.
//
// 2. Legacy (`data.url`) — the SQL still emits this for backward compat with
//    older app builds and as a fallback for the dev stub.
//
// `resolveNotificationRoute` prefers (1) when `kind` is present and falls
// through to (2) otherwise. Returns `null` when no route can be derived.

export type PushDataLike = {
  kind?: string;
  entity_id?: string;
  conversation_id?: string;
  url?: string;
  [key: string]: unknown;
};

export function resolveNotificationRoute(data: PushDataLike | undefined | null): string | null {
  if (!data) return null;

  const kind = typeof data.kind === 'string' ? data.kind : undefined;
  const entityId = typeof data.entity_id === 'string' ? data.entity_id : undefined;
  const conversationId =
    typeof data.conversation_id === 'string' ? data.conversation_id : undefined;
  const legacyUrl = typeof data.url === 'string' ? data.url : undefined;

  if (kind) {
    switch (kind) {
      case 'intro_received':
        return entityId ? `/(app)/intros/${entityId}` : '/(app)/(tabs)/inbox';

      // Direct message kinds — entity_id is the *message* id, not the
      // conversation id. We can only route to the chat when SQL also passed
      // conversation_id; otherwise we fall back to the chat list.
      case 'message_received':
      case 'image_received':
      case 'voice_received':
        return conversationId
          ? `/(app)/chats/${conversationId}`
          : '/(app)/(tabs)/chats';

      case 'meeting_proposal':
      case 'meeting_confirmed':
        return conversationId
          ? `/(app)/chats/${conversationId}`
          : '/(app)/(tabs)/inbox';

      // Opportunity interest — entity_id is the opportunity_id; route to detail.
      case 'opportunity_interest':
        return entityId
          ? `/(app)/opportunities/${entityId}`
          : '/(app)/(tabs)/opportunities';

      // Unknown kind — fall through to legacy url if SQL also supplied one.
      default:
        break;
    }
  }

  return legacyUrl ?? null;
}
