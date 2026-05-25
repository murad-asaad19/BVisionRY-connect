import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/domain/profile.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

class _FakeQuery implements ProfileQueryRunner {
  Map<String, dynamic>? row;
  String? calledFor;

  @override
  Future<Map<String, dynamic>?> selectById(String id) async {
    calledFor = id;
    return row;
  }
}

void main() {
  test('returns null when session is null and skips repo', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final _FakeQuery q = _FakeQuery();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authGatewayProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(ProfileRepository(q)),
      ],
    );
    addTearDown(container.dispose);

    // Ensure the stream provider has yielded its seed.
    await container.read(sessionProvider.future);
    final Profile? p = await container.read(profileProvider.future);
    expect(p, isNull);
    expect(q.calledFor, isNull);
  });

  test('returns parsed Profile for the current session uid', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u-9'));
    final _FakeQuery q = _FakeQuery()
      ..row = <String, dynamic>{
        'id': 'u-9',
        'onboarded': true,
        'suspended_at': null,
        'handle': 'h',
        'name': 'n',
        'private_mode': false,
      };
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authGatewayProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(ProfileRepository(q)),
      ],
    );
    addTearDown(container.dispose);

    final Profile? p = await container.read(profileProvider.future);
    expect(p, isA<Profile>());
    expect(p!.id, 'u-9');
    expect(p.onboarded, isTrue);
    expect(q.calledFor, 'u-9');
  });

  test('returns null when the profile row is missing', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u-x'));
    final _FakeQuery q = _FakeQuery(); // row left null
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        authGatewayProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(ProfileRepository(q)),
      ],
    );
    addTearDown(container.dispose);

    final Profile? p = await container.read(profileProvider.future);
    expect(p, isNull);
    expect(q.calledFor, 'u-x');
  });
}
