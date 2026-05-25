import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuery implements ProfileQueryRunner {
  Map<String, dynamic>? row;
  Object? throwable;
  String? capturedId;

  @override
  Future<Map<String, dynamic>?> selectById(String id) async {
    capturedId = id;
    if (throwable != null) throw throwable!;
    return row;
  }
}

void main() {
  test('returns parsed Profile when row exists', () async {
    final q = _FakeQuery()
      ..row = <String, dynamic>{
        'id': 'u-1',
        'onboarded': true,
        'suspended_at': null,
        'handle': 'mu',
        'name': 'Murad',
        'private_mode': false,
      };
    final repo = ProfileRepository(q);
    final p = await repo.fetchOwn('u-1');
    expect(p, isA<Profile>());
    expect(p!.id, 'u-1');
    expect(p.onboarded, isTrue);
    expect(q.capturedId, 'u-1');
  });

  test('returns null when row missing', () async {
    final q = _FakeQuery()..row = null;
    final repo = ProfileRepository(q);
    expect(await repo.fetchOwn('u-1'), isNull);
  });

  test('rethrows on error', () async {
    final q = _FakeQuery()..throwable = Exception('boom');
    final repo = ProfileRepository(q);
    expect(() => repo.fetchOwn('u-1'), throwsException);
  });
}
