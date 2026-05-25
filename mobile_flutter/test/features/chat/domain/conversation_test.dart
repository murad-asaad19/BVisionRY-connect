import 'package:connect_mobile/features/chat/domain/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Conversation.fromRow parses canonical pair', () {
    final c = Conversation.fromRow(<String, dynamic>{
      'id': 'c1',
      'participant_a_id': 'user-a',
      'participant_b_id': 'user-b',
      'last_message_at': '2026-05-25T10:00:00Z',
      'created_at': '2026-05-20T10:00:00Z',
    });
    expect(c.id, 'c1');
    expect(c.participantAId, 'user-a');
    expect(c.participantBId, 'user-b');
    expect(c.lastMessageAt, DateTime.utc(2026, 5, 25, 10));
    expect(c.createdAt, DateTime.utc(2026, 5, 20, 10));
  });

  test('Conversation.fromRow tolerates null last_message_at', () {
    final c = Conversation.fromRow(<String, dynamic>{
      'id': 'c1',
      'participant_a_id': 'a',
      'participant_b_id': 'b',
      'last_message_at': null,
      'created_at': '2026-05-20T10:00:00Z',
    });
    expect(c.lastMessageAt, isNull);
  });

  test('peerIdFor picks the OTHER participant', () {
    final c = Conversation.fromRow(<String, dynamic>{
      'id': 'c1',
      'participant_a_id': 'user-a',
      'participant_b_id': 'user-b',
      'created_at': '2026-05-20T10:00:00Z',
    });
    expect(c.peerIdFor('user-a'), 'user-b');
    expect(c.peerIdFor('user-b'), 'user-a');
    expect(() => c.peerIdFor('user-z'), throwsArgumentError);
  });
}
