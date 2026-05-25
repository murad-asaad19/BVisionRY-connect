import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/chat/data/chat_service.dart';
import 'package:connect_mobile/features/chat/domain/message.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGateway extends Mock implements ChatGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockGateway gw;
  late ChatService svc;

  setUp(() {
    gw = _MockGateway();
    svc = ChatService(gw);
  });

  group('listConversationOverview', () {
    test('calls RPC with no args and parses rows', () async {
      when(
        () => gw.rpc('list_conversation_overview'),
      ).thenAnswer((_) async => <Map<String, dynamic>>[
        <String, dynamic>{
          'conversation_id': 'c1',
          'peer_id': 'u2',
          'peer_name': 'Ada',
          'peer_handle': 'ada',
          'peer_photo_url': null,
          'last_message_body': 'hi',
          'last_message_kind': 'text',
          'last_message_at': '2026-05-25T10:00:00Z',
          'unread_count': 1,
          'is_muted': false,
        },
      ]);
      final rows = await svc.listConversationOverview();
      expect(rows, hasLength(1));
      expect(rows.first.lastMessageKind, MessageKind.text);
      verify(() => gw.rpc('list_conversation_overview')).called(1);
    });

    test('returns empty list when RPC returns null', () async {
      when(
        () => gw.rpc('list_conversation_overview'),
      ).thenAnswer((_) async => null);
      expect(await svc.listConversationOverview(), isEmpty);
    });
  });

  group('listConversationUnread', () {
    test('maps RPC rows into typed records', () async {
      when(
        () => gw.rpc('list_conversation_unread'),
      ).thenAnswer((_) async => <Map<String, dynamic>>[
        <String, dynamic>{'conversation_id': 'c1', 'unread_count': 3},
        <String, dynamic>{'conversation_id': 'c2', 'unread_count': 0},
      ]);
      final rows = await svc.listConversationUnread();
      expect(rows, hasLength(2));
      expect(rows.first.conversationId, 'c1');
      expect(rows.first.unreadCount, 3);
    });
  });

  test('markConversationRead passes conversation id', () async {
    when(
      () => gw.rpc(
        'mark_conversation_read',
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) async => null);
    await svc.markConversationRead('c1');
    verify(
      () => gw.rpc(
        'mark_conversation_read',
        params: <String, dynamic>{'p_conversation_id': 'c1'},
      ),
    ).called(1);
  });

  test('muteConversation passes conversation id', () async {
    when(
      () => gw.rpc('mute_conversation', params: any(named: 'params')),
    ).thenAnswer((_) async => null);
    await svc.muteConversation('c1');
    verify(
      () => gw.rpc(
        'mute_conversation',
        params: <String, dynamic>{'p_conversation_id': 'c1'},
      ),
    ).called(1);
  });

  test('unmuteConversation passes conversation id', () async {
    when(
      () => gw.rpc('unmute_conversation', params: any(named: 'params')),
    ).thenAnswer((_) async => null);
    await svc.unmuteConversation('c1');
    verify(
      () => gw.rpc(
        'unmute_conversation',
        params: <String, dynamic>{'p_conversation_id': 'c1'},
      ),
    ).called(1);
  });

  group('editMessage', () {
    test('returns updated Message from bare map', () async {
      when(
        () => gw.rpc('edit_message', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'id': 'm1',
          'conversation_id': 'c1',
          'sender_id': 'u1',
          'kind': 'text',
          'body': 'edited',
          'edited_at': '2026-05-25T10:05:00Z',
          'created_at': '2026-05-25T10:00:00Z',
        },
      );
      final m = await svc.editMessage('m1', 'edited');
      expect(m.id, 'm1');
      expect(m.body, 'edited');
      expect(m.isEdited, isTrue);
    });

    test('handles list-of-one envelope', () async {
      when(
        () => gw.rpc('edit_message', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'm1',
            'conversation_id': 'c1',
            'sender_id': 'u1',
            'kind': 'text',
            'body': 'edited',
            'created_at': '2026-05-25T10:00:00Z',
          },
        ],
      );
      final m = await svc.editMessage('m1', 'edited');
      expect(m.id, 'm1');
    });

    test('maps PostgrestException to AppException', () async {
      when(
        () => gw.rpc('edit_message', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(message: 'too late', code: '22023'),
      );
      await expectLater(
        svc.editMessage('m1', 'hi'),
        throwsA(isA<AppException>()),
      );
    });
  });

  test('deleteMessage returns tombstoned Message', () async {
    when(
      () => gw.rpc('delete_message', params: any(named: 'params')),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'id': 'm1',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'kind': 'text',
        'deleted_at': '2026-05-25T10:10:00Z',
        'created_at': '2026-05-25T10:00:00Z',
      },
    );
    final m = await svc.deleteMessage('m1');
    expect(m.isTombstone, isTrue);
  });

  test('forbidden RPC bubbles up as ForbiddenException', () async {
    when(() => gw.rpc('mute_conversation', params: any(named: 'params')))
        .thenThrow(const PostgrestException(message: 'denied', code: '42501'));
    await expectLater(
      svc.muteConversation('c1'),
      throwsA(isA<ForbiddenException>()),
    );
  });

  // Re-export shape sanity check.
  test('Message exported from domain', () {
    expect(Message, isNotNull);
  });
}
