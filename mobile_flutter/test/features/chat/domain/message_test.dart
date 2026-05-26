import 'package:connect_mobile/features/chat/domain/message.dart';
import 'package:connect_mobile/features/chat/domain/message_kind.dart';
import 'package:connect_mobile/features/chat/domain/transcript_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message.fromRow', () {
    test('parses a text row', () {
      final m = Message.fromRow(<String, dynamic>{
        'id': '11111111-1111-1111-1111-111111111111',
        'conversation_id': '22222222-2222-2222-2222-222222222222',
        'sender_id': '33333333-3333-3333-3333-333333333333',
        'body': 'hello',
        'kind': 'text',
        'created_at': '2026-05-25T10:00:00Z',
      });
      expect(m.kind, MessageKind.text);
      expect(m.body, 'hello');
      expect(m.isTombstone, isFalse);
      expect(m.isEdited, isFalse);
    });

    test('parses a voice row with transcript fields', () {
      final m = Message.fromRow(<String, dynamic>{
        'id': 'v1',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'kind': 'voice',
        'media_path': 'c1/m1/voice.m4a',
        'media_duration_ms': 30000,
        'media_size_bytes': 240000,
        'transcript': 'hi there',
        'transcript_status': 'ready',
        'created_at': '2026-05-25T10:00:00Z',
      });
      expect(m.kind, MessageKind.voice);
      expect(m.mediaDurationMs, 30000);
      expect(m.mediaSizeBytes, 240000);
      expect(m.transcript, 'hi there');
      expect(m.transcriptStatus, TranscriptStatus.ready);
    });

    test('flags tombstone and edited', () {
      final t = Message.fromRow(<String, dynamic>{
        'id': '11111111-1111-1111-1111-111111111111',
        'conversation_id': '22222222-2222-2222-2222-222222222222',
        'sender_id': '33333333-3333-3333-3333-333333333333',
        'kind': 'text',
        'deleted_at': '2026-05-25T11:00:00Z',
        'created_at': '2026-05-25T10:00:00Z',
      });
      expect(t.isTombstone, isTrue);

      final e = Message.fromRow(<String, dynamic>{
        'id': '44444444-4444-4444-4444-444444444444',
        'conversation_id': '22222222-2222-2222-2222-222222222222',
        'sender_id': '33333333-3333-3333-3333-333333333333',
        'kind': 'text',
        'body': 'edited',
        'edited_at': '2026-05-25T10:05:00Z',
        'created_at': '2026-05-25T10:00:00Z',
      });
      expect(e.isEdited, isTrue);
    });
  });

  group('canEditBy', () {
    const userId = 'user-1';
    final now = DateTime.utc(2026, 5, 25, 10);
    Message base() => Message(
          id: 'm1',
          conversationId: 'c1',
          senderId: userId,
          kind: MessageKind.text,
          body: 'hi',
          createdAt: now,
        );

    test('own text within 15 min', () {
      expect(
        base().canEditBy(
          userId: userId,
          at: now.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    });

    test('rejects after 15 min', () {
      expect(
        base().canEditBy(
          userId: userId,
          at: now.add(const Duration(minutes: 16)),
        ),
        isFalse,
      );
    });

    test('rejects other user', () {
      expect(base().canEditBy(userId: 'other', at: now), isFalse);
    });

    test('rejects non-text kind', () {
      final voice = base().copyWith(kind: MessageKind.voice);
      expect(voice.canEditBy(userId: userId, at: now), isFalse);
    });

    test('rejects tombstoned message', () {
      final t = base().copyWith(deletedAt: now);
      expect(t.canEditBy(userId: userId, at: now), isFalse);
    });
  });

  group('canDeleteBy', () {
    const userId = 'user-1';
    final now = DateTime.utc(2026, 5, 25, 10);

    test('own non-deleted message', () {
      final m = Message(
        id: 'm1',
        conversationId: 'c1',
        senderId: userId,
        kind: MessageKind.voice,
        createdAt: now,
      );
      expect(m.canDeleteBy(userId: userId), isTrue);
    });

    test('rejects other user', () {
      final m = Message(
        id: 'm1',
        conversationId: 'c1',
        senderId: userId,
        kind: MessageKind.text,
        createdAt: now,
      );
      expect(m.canDeleteBy(userId: 'other'), isFalse);
    });

    test('rejects already-deleted', () {
      final m = Message(
        id: 'm1',
        conversationId: 'c1',
        senderId: userId,
        kind: MessageKind.text,
        createdAt: now,
        deletedAt: now,
      );
      expect(m.canDeleteBy(userId: userId), isFalse);
    });
  });
}
