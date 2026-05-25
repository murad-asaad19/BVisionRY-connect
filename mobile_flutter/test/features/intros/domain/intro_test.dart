import 'package:connect_mobile/features/intros/domain/intro.dart';
import 'package:connect_mobile/features/intros/domain/intro_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Intro.fromJson', () {
    test('parses a delivered direct row', () {
      final json = <String, dynamic>{
        'id': '11111111-1111-1111-1111-111111111111',
        'sender_id': '22222222-2222-2222-2222-222222222222',
        'recipient_id': '33333333-3333-3333-3333-333333333333',
        'note': 'x' * 100,
        'state': 'delivered',
        'kind': 'direct',
        'warm_target_id': null,
        'conversation_id': null,
        'expires_at': '2026-06-08T00:00:00.000Z',
        'created_at': '2026-05-25T00:00:00.000Z',
        'declined_at': null,
      };
      final intro = Intro.fromJson(json);
      expect(intro.id, json['id']);
      expect(intro.state, IntroState.delivered);
      expect(intro.kind, IntroKind.direct);
      expect(intro.warmTargetId, isNull);
      expect(intro.conversationId, isNull);
      expect(intro.note.length, 100);
      expect(intro.expiresAt.isUtc, isTrue);
      expect(intro.createdAt.isUtc, isTrue);
      expect(intro.declinedAt, isNull);
      expect(intro.sender, isNull);
      expect(intro.recipient, isNull);
    });

    test('parses a connected row with conversation_id', () {
      final json = <String, dynamic>{
        'id': 'a',
        'sender_id': 'b',
        'recipient_id': 'c',
        'note': 'x' * 90,
        'state': 'connected',
        'kind': 'direct',
        'warm_target_id': null,
        'conversation_id': 'conv-1',
        'expires_at': '2026-06-08T00:00:00.000Z',
        'created_at': '2026-05-25T00:00:00.000Z',
        'declined_at': null,
      };
      final intro = Intro.fromJson(json);
      expect(intro.conversationId, equals('conv-1'));
      expect(intro.state, IntroState.connected);
    });

    test('parses a warm_request row with warm_target_id', () {
      final json = <String, dynamic>{
        'id': 'wr-1',
        'sender_id': 'asker',
        'recipient_id': 'mutual',
        'note': 'x' * 90,
        'state': 'delivered',
        'kind': 'warm_request',
        'warm_target_id': 'target',
        'conversation_id': null,
        'expires_at': '2026-06-08T00:00:00.000Z',
        'created_at': '2026-05-25T00:00:00.000Z',
        'declined_at': null,
      };
      final intro = Intro.fromJson(json);
      expect(intro.kind, IntroKind.warmRequest);
      expect(intro.warmTargetId, equals('target'));
      expect(intro.isWarmRequest, isTrue);
      expect(intro.isDirect, isFalse);
    });

    test('parses declined_at when present', () {
      final json = <String, dynamic>{
        'id': 'd',
        'sender_id': 's',
        'recipient_id': 'r',
        'note': 'x' * 90,
        'state': 'declined',
        'kind': 'direct',
        'warm_target_id': null,
        'conversation_id': null,
        'expires_at': '2026-06-08T00:00:00.000Z',
        'created_at': '2026-05-25T00:00:00.000Z',
        'declined_at': '2026-05-26T00:00:00.000Z',
      };
      final intro = Intro.fromJson(json);
      expect(intro.declinedAt, isNotNull);
      expect(intro.declinedAt!.isUtc, isTrue);
    });
  });

  group('Intro.isActionable', () {
    final base = Intro(
      id: 'x',
      senderId: 'a',
      recipientId: 'b',
      note: 'x' * 90,
      state: IntroState.delivered,
      kind: IntroKind.direct,
      warmTargetId: null,
      conversationId: null,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      createdAt: DateTime.now().toUtc(),
      declinedAt: null,
    );

    test('true for delivered + not expired', () {
      expect(base.isActionable, isTrue);
    });

    test('false for accepted', () {
      expect(base.copyWith(state: IntroState.accepted).isActionable, isFalse);
    });

    test('false for expired state', () {
      expect(base.copyWith(state: IntroState.expired).isActionable, isFalse);
    });

    test('false when expires_at is in the past', () {
      expect(
        base
            .copyWith(
              expiresAt:
                  DateTime.now().toUtc().subtract(const Duration(days: 1)),
            )
            .isActionable,
        isFalse,
      );
    });
  });
}
