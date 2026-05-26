/// Maps a push-notification payload `kind` to an in-app deep-link path.
///
/// Phase 12 wires the FCM tap handler; this file is the canonical lookup it
/// consults. Each feature phase appends its own kinds — Phase 10 adds
/// `opportunity_interest`.
///
/// Returns `null` when the kind is unrecognised or when the payload is
/// missing fields required to resolve the route (e.g. `entityId` for an
/// opportunity-scoped kind). Callers should fall back to the relevant tab
/// root (`/opportunities` for opportunity kinds, `/inbox` for intros, etc.).
String? resolveNotificationRoute({
  required String kind,
  String? entityId,
  String? conversationId,
}) {
  switch (kind) {
    case 'opportunity_interest':
      return entityId != null ? '/opportunities/$entityId' : '/opportunities';
    case 'intro_received':
    case 'intro_accepted':
    case 'intro_expired':
      return entityId != null ? '/intros/$entityId' : '/inbox';
    case 'chat_message':
    case 'meeting_confirmed':
    case 'meeting_proposed':
    case 'meeting_declined':
      return conversationId != null ? '/chats/$conversationId' : '/chats';
    case 'meeting_review_pending':
      return entityId != null ? '/meetings/$entityId/review' : '/chats';
    default:
      return null;
  }
}
