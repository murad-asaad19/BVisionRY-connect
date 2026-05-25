import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/chat/data/messages_service.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGateway extends Mock implements MessagesGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  late _MockGateway gw;
  late MessagesService svc;

  setUp(() {
    gw = _MockGateway();
    svc = MessagesService(gw);
  });

  group('listMessages', () {
    test('returns parsed Messages newest-first', () async {
      when(
        () => gw.selectMessages(
          'c1',
          beforeCursor: null,
          limit: 30,
        ),
      ).thenAnswer(
        (_) async => [
          <String, dynamic>{
            'id': 'm2',
            'conversation_id': 'c1',
            'sender_id': 'u1',
            'kind': 'text',
            'body': 'second',
            'created_at': '2026-05-25T10:01:00Z',
          },
          <String, dynamic>{
            'id': 'm1',
            'conversation_id': 'c1',
            'sender_id': 'u1',
            'kind': 'text',
            'body': 'first',
            'created_at': '2026-05-25T10:00:00Z',
          },
        ],
      );
      final rows = await svc.listMessages('c1');
      expect(rows, hasLength(2));
      expect(rows.first.id, 'm2');
      expect(rows.first.kind, MessageKind.text);
    });

    test('forwards beforeCursor for pagination', () async {
      final cursor = DateTime.utc(2026, 5, 25, 10);
      when(
        () => gw.selectMessages(
          'c1',
          beforeCursor: cursor,
          limit: 30,
        ),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);
      await svc.listMessages('c1', beforeCursor: cursor);
      verify(
        () => gw.selectMessages('c1', beforeCursor: cursor, limit: 30),
      ).called(1);
    });

    test('maps PostgrestException to AppException', () async {
      when(
        () => gw.selectMessages(
          'c1',
          beforeCursor: null,
          limit: 30,
        ),
      ).thenThrow(const PostgrestException(message: 'denied', code: '42501'));
      await expectLater(
        svc.listMessages('c1'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('sendTextMessage', () {
    test('inserts with current user id and returns Message', () async {
      when(() => gw.currentUserId).thenReturn('u1');
      when(
        () => gw.insertTextMessage(
          conversationId: 'c1',
          senderId: 'u1',
          body: 'hi',
        ),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'id': 'm1',
          'conversation_id': 'c1',
          'sender_id': 'u1',
          'kind': 'text',
          'body': 'hi',
          'created_at': '2026-05-25T10:00:00Z',
        },
      );
      final m = await svc.sendTextMessage(conversationId: 'c1', body: 'hi');
      expect(m.id, 'm1');
      expect(m.body, 'hi');
    });

    test('throws UnauthenticatedException when no session', () async {
      when(() => gw.currentUserId).thenReturn(null);
      await expectLater(
        svc.sendTextMessage(conversationId: 'c1', body: 'hi'),
        throwsA(isA<UnauthenticatedException>()),
      );
    });

    test('maps Postgrest insert failure', () async {
      when(() => gw.currentUserId).thenReturn('u1');
      when(
        () => gw.insertTextMessage(
          conversationId: 'c1',
          senderId: 'u1',
          body: 'hi',
        ),
      ).thenThrow(
        const PostgrestException(message: 'denied', code: '42501'),
      );
      await expectLater(
        svc.sendTextMessage(conversationId: 'c1', body: 'hi'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('fetchMessage', () {
    test('returns null when row missing', () async {
      when(() => gw.selectMessage('m1')).thenAnswer((_) async => null);
      expect(await svc.fetchMessage('m1'), isNull);
    });

    test('returns Message when row present', () async {
      when(() => gw.selectMessage('m1')).thenAnswer(
        (_) async => <String, dynamic>{
          'id': 'm1',
          'conversation_id': 'c1',
          'sender_id': 'u1',
          'kind': 'text',
          'body': 'hi',
          'created_at': '2026-05-25T10:00:00Z',
        },
      );
      final m = await svc.fetchMessage('m1');
      expect(m!.id, 'm1');
    });
  });
}
