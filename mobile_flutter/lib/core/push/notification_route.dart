import '../routing/routes.dart';

/// Translates an FCM `data` map (and optional legacy `payload`) into a
/// go_router path. Spec section 7.4 verbatim:
///
/// | kind                                            | route                          | fallback           |
/// |-------------------------------------------------|--------------------------------|--------------------|
/// | intro_received, intro_accepted                  | /intros/{entity_id}            | /inbox             |
/// | message_received, image_received, voice_received| /chats/{conversation_id}       | /chats             |
/// | meeting_proposal, meeting_confirmed             | /chats/{conversation_id}       | /inbox             |
/// | opportunity_interest                            | /opportunities/{entity_id}     | /opportunities     |
/// | (unknown)                                       | payload.url                    | /home              |
///
/// FCM stringifies non-string `data` values on the way to the device, but on
/// the way IN (e.g. from a unit test that hand-builds the map) we may see a
/// raw `int`. `.toString()` covers both cases without forcing every caller to
/// pre-stringify.
String resolvePushRoute(
  Map<String, dynamic> data,
  Map<String, dynamic>? payload,
) {
  final String? kind = (data['kind'] as Object?)?.toString();
  final String? entityId = (data['entity_id'] as Object?)?.toString();
  final String? conversationId =
      (data['conversation_id'] as Object?)?.toString();

  switch (kind) {
    case 'intro_received':
    case 'intro_accepted':
      return (entityId != null && entityId.isNotEmpty)
          ? Routes.intro(entityId)
          : Routes.inbox;

    case 'message_received':
    case 'image_received':
    case 'voice_received':
      return (conversationId != null && conversationId.isNotEmpty)
          ? Routes.chat(conversationId)
          : Routes.chats;

    case 'meeting_proposal':
    case 'meeting_confirmed':
      return (conversationId != null && conversationId.isNotEmpty)
          ? Routes.chat(conversationId)
          : Routes.inbox;

    case 'opportunity_interest':
      return (entityId != null && entityId.isNotEmpty)
          ? Routes.opportunity(entityId)
          : Routes.opportunities;

    default:
      final String? legacy = (payload?['url'] as Object?)?.toString();
      if (legacy != null && legacy.isNotEmpty) return legacy;
      return Routes.home;
  }
}
