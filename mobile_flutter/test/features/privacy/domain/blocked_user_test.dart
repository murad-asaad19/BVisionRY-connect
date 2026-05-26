import 'package:connect_mobile/features/privacy/domain/blocked_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlockedUser', () {
    test('fromJson parses list_blocked_users row shape', () {
      final row = <String, dynamic>{
        'blocked_id': '11111111-1111-1111-1111-111111111111',
        'handle': 'alice',
        'name': 'Alice Anderson',
        'photo_url': 'https://cdn.example/a.png',
        'created_at': '2026-05-20T10:00:00Z',
      };
      final u = BlockedUser.fromJson(row);
      expect(u.blockedId, '11111111-1111-1111-1111-111111111111');
      expect(u.handle, 'alice');
      expect(u.name, 'Alice Anderson');
      expect(u.photoUrl, 'https://cdn.example/a.png');
      expect(u.createdAt, DateTime.parse('2026-05-20T10:00:00Z').toUtc());
    });

    test('tolerates null photo_url', () {
      final u = BlockedUser.fromJson(<String, dynamic>{
        'blocked_id': 'x',
        'handle': 'h',
        'name': 'n',
        'photo_url': null,
        'created_at': '2026-05-20T10:00:00Z',
      });
      expect(u.photoUrl, isNull);
    });

    test('createdAt is normalised to UTC', () {
      final u = BlockedUser.fromJson(<String, dynamic>{
        'blocked_id': 'x',
        'handle': 'h',
        'name': 'n',
        'photo_url': null,
        'created_at': '2026-05-20T12:00:00+02:00',
      });
      expect(u.createdAt.isUtc, isTrue);
      expect(u.createdAt.hour, 10); // +02:00 -> 10:00 UTC
    });
  });
}
