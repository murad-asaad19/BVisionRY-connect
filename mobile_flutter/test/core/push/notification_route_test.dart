import 'package:connect_mobile/core/push/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolvePushRoute - spec section 7.4', () {
    test('intro_received with entity_id -> /intros/<id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'intro_received',
          'entity_id': 'intro-1',
        },
        null,
      );
      expect(route, '/intros/intro-1');
    });

    test('intro_received without entity_id -> /inbox fallback', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{'kind': 'intro_received'},
        null,
      );
      expect(route, '/inbox');
    });

    test('intro_accepted with entity_id -> /intros/<id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'intro_accepted',
          'entity_id': 'intro-2',
        },
        null,
      );
      expect(route, '/intros/intro-2');
    });

    test('message_received with conversation_id -> /chats/<id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'message_received',
          'conversation_id': 'conv-1',
        },
        null,
      );
      expect(route, '/chats/conv-1');
    });

    test('image_received with conversation_id -> /chats/<id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'image_received',
          'conversation_id': 'conv-1',
        },
        null,
      );
      expect(route, '/chats/conv-1');
    });

    test('voice_received with conversation_id -> /chats/<id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'voice_received',
          'conversation_id': 'conv-1',
        },
        null,
      );
      expect(route, '/chats/conv-1');
    });

    test('message_received without conversation_id -> /chats fallback', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{'kind': 'message_received'},
        null,
      );
      expect(route, '/chats');
    });

    test('meeting_proposal -> /chats/<conversation_id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'meeting_proposal',
          'conversation_id': 'conv-9',
        },
        null,
      );
      expect(route, '/chats/conv-9');
    });

    test('meeting_proposal without conversation_id -> /inbox fallback', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{'kind': 'meeting_proposal'},
        null,
      );
      expect(route, '/inbox');
    });

    test('meeting_confirmed -> /chats/<conversation_id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'meeting_confirmed',
          'conversation_id': 'conv-9',
        },
        null,
      );
      expect(route, '/chats/conv-9');
    });

    test('opportunity_interest with entity_id -> /opportunities/<id>', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{
          'kind': 'opportunity_interest',
          'entity_id': 'opp-1',
        },
        null,
      );
      expect(route, '/opportunities/opp-1');
    });

    test('opportunity_interest without entity_id -> /opportunities fallback',
        () {
      final String route = resolvePushRoute(
        const <String, dynamic>{'kind': 'opportunity_interest'},
        null,
      );
      expect(route, '/opportunities');
    });

    test('unknown kind falls through to payload.url when present', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{'kind': 'experimental_kind'},
        const <String, dynamic>{'url': '/profile/edit'},
      );
      expect(route, '/profile/edit');
    });

    test('no kind, no payload -> /home', () {
      final String route = resolvePushRoute(const <String, dynamic>{}, null);
      expect(route, '/home');
    });

    test('unknown kind without payload.url -> /home', () {
      final String route = resolvePushRoute(
        const <String, dynamic>{'kind': 'experimental_kind'},
        const <String, dynamic>{},
      );
      expect(route, '/home');
    });

    test('handles non-string values gracefully (FCM stringifies numbers)', () {
      final String route = resolvePushRoute(
        <String, dynamic>{'kind': 'intro_received', 'entity_id': 42},
        null,
      );
      expect(route, '/intros/42');
    });
  });
}
