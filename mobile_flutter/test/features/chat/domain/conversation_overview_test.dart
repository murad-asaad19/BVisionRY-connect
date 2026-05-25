import 'package:connect_mobile/features/chat/domain/conversation_overview.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ConversationOverview.fromRow parses RPC row', () {
    final o = ConversationOverview.fromRow(<String, dynamic>{
      'conversation_id': 'c1',
      'peer_id': 'u2',
      'peer_name': 'Ada Lovelace',
      'peer_handle': 'ada',
      'peer_photo_url': null,
      'last_message_body': 'hi',
      'last_message_kind': 'text',
      'last_message_at': '2026-05-25T10:00:00Z',
      'unread_count': 3,
      'is_muted': false,
    });
    expect(o.conversationId, 'c1');
    expect(o.peerName, 'Ada Lovelace');
    expect(o.peerHandle, 'ada');
    expect(o.lastMessageKind, MessageKind.text);
    expect(o.lastMessageBody, 'hi');
    expect(o.unreadCount, 3);
    expect(o.isMuted, isFalse);
  });

  test('supports voice/image/meeting kinds and null body', () {
    final v = ConversationOverview.fromRow(<String, dynamic>{
      'conversation_id': 'c1',
      'peer_id': 'u2',
      'peer_name': 'A',
      'peer_handle': 'a',
      'peer_photo_url': null,
      'last_message_body': null,
      'last_message_kind': 'voice',
      'last_message_at': '2026-05-25T10:00:00Z',
      'last_message_duration_ms': 30000,
      'unread_count': 0,
      'is_muted': true,
    });
    expect(v.lastMessageKind, MessageKind.voice);
    expect(v.lastMessageBody, isNull);
    expect(v.lastMessageDurationMs, 30000);
    expect(v.isMuted, isTrue);
  });

  test('blank conversation (no messages yet)', () {
    final blank = ConversationOverview.fromRow(<String, dynamic>{
      'conversation_id': 'c1',
      'peer_id': 'u2',
      'peer_name': 'B',
      'peer_handle': 'b',
      'peer_photo_url': null,
      'last_message_body': null,
      'last_message_kind': null,
      'last_message_at': null,
      'unread_count': 0,
      'is_muted': false,
    });
    expect(blank.lastMessageKind, isNull);
    expect(blank.lastMessageAt, isNull);
    expect(blank.unreadCount, 0);
  });
}
