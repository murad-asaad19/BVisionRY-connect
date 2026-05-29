import 'package:connect_mobile/core/routing/routes.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/auth/providers/route_guard_provider.dart';
import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

class _Q implements ProfileQueryRunner {
  _Q(this.row);
  final Map<String, dynamic>? row;
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => row;
}

ProviderContainer _container(FakeAuthGateway auth, _Q q) {
  return ProviderContainer(
    overrides: <Override>[
      authGatewayProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(ProfileRepository(q)),
    ],
  );
}

void main() {
  test('no session -> /sign-in', () async {
    final FakeAuthGateway auth = FakeAuthGateway();
    final ProviderContainer c = _container(auth, _Q(null));
    addTearDown(c.dispose);

    await c.read(sessionProvider.future);
    await c.read(profileProvider.future);
    expect(c.read(routeGuardProvider), Routes.signIn);
  });

  test('session + onboarded profile -> /home', () async {
    final FakeAuthGateway auth = FakeAuthGateway()
      ..pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u'));
    final ProviderContainer c = _container(
      auth,
      _Q(<String, dynamic>{
        'id': 'u',
        'onboarded': true,
        'suspended_at': null,
        'tos_accepted_at': '2026-01-01T00:00:00Z',
        'privacy_accepted_at': '2026-01-01T00:00:00Z',
      }),
    );
    addTearDown(c.dispose);

    await c.read(sessionProvider.future);
    await c.read(profileProvider.future);
    expect(c.read(routeGuardProvider), Routes.home);
  });

  test('session + profile without recorded consent -> /consent', () async {
    final FakeAuthGateway auth = FakeAuthGateway()
      ..pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u'));
    final ProviderContainer c = _container(
      auth,
      _Q(<String, dynamic>{
        'id': 'u',
        'onboarded': false,
        'suspended_at': null,
        // OAuth / magic-link sign-up: no consent recorded yet.
        'tos_accepted_at': null,
        'privacy_accepted_at': null,
      }),
    );
    addTearDown(c.dispose);

    await c.read(sessionProvider.future);
    await c.read(profileProvider.future);
    expect(c.read(routeGuardProvider), Routes.consent);
  });

  test('session + suspended_at NOT NULL -> /suspended', () async {
    final FakeAuthGateway auth = FakeAuthGateway()
      ..pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u'));
    final ProviderContainer c = _container(
      auth,
      _Q(<String, dynamic>{
        'id': 'u',
        'onboarded': true,
        'suspended_at': DateTime.now().toIso8601String(),
      }),
    );
    addTearDown(c.dispose);

    await c.read(sessionProvider.future);
    await c.read(profileProvider.future);
    expect(c.read(routeGuardProvider), Routes.suspended);
  });

  test('session + not onboarded -> /onboarding/goal', () async {
    final FakeAuthGateway auth = FakeAuthGateway()
      ..pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u'));
    final ProviderContainer c = _container(
      auth,
      _Q(<String, dynamic>{
        'id': 'u',
        'onboarded': false,
        'suspended_at': null,
        // Consent recorded (e.g. email sign-up) but onboarding not finished.
        'tos_accepted_at': '2026-01-01T00:00:00Z',
        'privacy_accepted_at': '2026-01-01T00:00:00Z',
      }),
    );
    addTearDown(c.dispose);

    await c.read(sessionProvider.future);
    await c.read(profileProvider.future);
    expect(c.read(routeGuardProvider), Routes.onboardingGoal);
  });

  test(
    'session + missing profile row -> onboarding (treated as not onboarded)',
    () async {
      final FakeAuthGateway auth = FakeAuthGateway()
        ..pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u'));
      final ProviderContainer c = _container(auth, _Q(null));
      addTearDown(c.dispose);

      await c.read(sessionProvider.future);
      await c.read(profileProvider.future);
      expect(c.read(routeGuardProvider), Routes.onboardingGoal);
    },
  );
}
