import 'package:connect_mobile/features/connections/domain/connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Connection.fromJson parses a complete row', () {
    final json = <String, dynamic>{
      'user_id': 'u1',
      'handle': 'alice',
      'name': 'Alice',
      'photo_url': 'https://x/p.jpg',
      'primary_role': 'founder',
      'conversation_id': 'c1',
      'connected_at': '2026-05-20T12:00:00.000Z',
    };
    final c = Connection.fromJson(json);
    expect(c.userId, 'u1');
    expect(c.handle, 'alice');
    expect(c.name, 'Alice');
    expect(c.photoUrl, equals('https://x/p.jpg'));
    expect(c.primaryRole, equals('founder'));
    expect(c.conversationId, 'c1');
    expect(c.connectedAt.isUtc, isTrue);
  });

  test('Connection handles null photo + role', () {
    final json = <String, dynamic>{
      'user_id': 'u2',
      'handle': 'bob',
      'name': 'Bob',
      'photo_url': null,
      'primary_role': null,
      'conversation_id': 'c2',
      'connected_at': '2026-05-20T00:00:00.000Z',
    };
    final c = Connection.fromJson(json);
    expect(c.photoUrl, isNull);
    expect(c.primaryRole, isNull);
  });
}
