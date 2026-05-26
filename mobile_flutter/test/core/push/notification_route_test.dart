import 'package:connect_mobile/core/push/notification_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveNotificationRoute', () {
    test('opportunity_interest with entityId -> /opportunities/<id>', () {
      final String? r = resolveNotificationRoute(
        kind: 'opportunity_interest',
        entityId: 'oid',
        conversationId: null,
      );
      expect(r, '/opportunities/oid');
    });

    test('opportunity_interest without entityId -> /opportunities', () {
      final String? r = resolveNotificationRoute(
        kind: 'opportunity_interest',
        entityId: null,
        conversationId: null,
      );
      expect(r, '/opportunities');
    });

    test('intro_received with entityId -> /intros/<id>', () {
      expect(
        resolveNotificationRoute(
          kind: 'intro_received',
          entityId: 'iid',
        ),
        '/intros/iid',
      );
    });

    test('chat_message with conversationId -> /chats/<id>', () {
      expect(
        resolveNotificationRoute(
          kind: 'chat_message',
          conversationId: 'cid',
        ),
        '/chats/cid',
      );
    });

    test('meeting_review_pending with entityId -> /meetings/<id>/review', () {
      expect(
        resolveNotificationRoute(
          kind: 'meeting_review_pending',
          entityId: 'mid',
        ),
        '/meetings/mid/review',
      );
    });

    test('unknown kind returns null', () {
      expect(resolveNotificationRoute(kind: 'mystery'), isNull);
    });
  });
}
