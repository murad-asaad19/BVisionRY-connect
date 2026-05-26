// OwnProfileController — Phase 4 mutation surface on top of the Phase 2
// profileProvider. Update / togglePrivateMode / refresh all invalidate the
// underlying provider so any consumer re-fetches.
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/profile/data/profile_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/providers/own_profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';

class _FakeQueryRunner implements ProfileQueryRunner {
  _FakeQueryRunner(this._row);
  Map<String, dynamic>? _row;
  int calls = 0;

  void setRow(Map<String, dynamic>? row) => _row = row;

  @override
  Future<Map<String, dynamic>?> selectById(String id) async {
    calls++;
    return _row;
  }
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService() : super(_NeverCalledGateway());

  Map<String, dynamic>? lastUpdatePatch;
  String? lastUpdateUserId;
  bool? lastPrivateMode;
  Profile updateResult = Profile.empty('u-1');

  @override
  Future<Profile> updateProfile({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    lastUpdateUserId = userId;
    lastUpdatePatch = patch;
    return updateResult;
  }

  @override
  Future<void> setPrivateMode(bool value) async {
    lastPrivateMode = value;
  }
}

class _NeverCalledGateway implements ProfileGateway {
  @override
  Future<Map<String, dynamic>?> fetchById(String id) =>
      throw StateError('not used in these tests');
  @override
  Future<Map<String, dynamic>> updateById({
    required String id,
    required Map<String, dynamic> patch,
  }) =>
      throw StateError('not used in these tests');
  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      throw StateError('not used in these tests');
  @override
  Future<FunctionResponse> invokeFunction(String name, {Object? body}) =>
      throw StateError('not used in these tests');
}

ProviderContainer _makeContainer({
  required FakeAuthGateway auth,
  required _FakeQueryRunner runner,
  required _FakeProfileService service,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authGatewayProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(ProfileRepository(runner)),
      profileServiceProvider.overrideWithValue(service),
    ],
  );
}

void main() {
  group('OwnProfileController', () {
    test('build() returns whatever profileProvider returns', () async {
      final FakeAuthGateway auth = FakeAuthGateway();
      auth.pushAuthState(
          AuthChangeEvent.initialSession, fakeSession(id: 'u-1'),);
      final _FakeQueryRunner runner = _FakeQueryRunner(<String, dynamic>{
        'id': 'u-1',
        'handle': 'h',
        'onboarded': true,
      });
      final _FakeProfileService service = _FakeProfileService();
      final ProviderContainer container =
          _makeContainer(auth: auth, runner: runner, service: service);
      addTearDown(container.dispose);

      final Profile? result =
          await container.read(ownProfileControllerProvider.future);
      expect(result, isNotNull);
      expect(result!.id, 'u-1');
      expect(result.handle, 'h');
    });

    test('updateOwnProfile patches the row and invalidates profileProvider',
        () async {
      final FakeAuthGateway auth = FakeAuthGateway();
      auth.pushAuthState(
          AuthChangeEvent.initialSession, fakeSession(id: 'u-1'),);
      final _FakeQueryRunner runner = _FakeQueryRunner(<String, dynamic>{
        'id': 'u-1',
        'handle': 'h',
        'onboarded': true,
        'headline': 'old',
      });
      final _FakeProfileService service = _FakeProfileService()
        ..updateResult = Profile.empty('u-1').copyWith(headline: 'new');
      final ProviderContainer container =
          _makeContainer(auth: auth, runner: runner, service: service);
      addTearDown(container.dispose);

      // Prime the underlying provider so we can observe invalidation.
      await container.read(ownProfileControllerProvider.future);
      final int callsBefore = runner.calls;

      await container
          .read(ownProfileControllerProvider.notifier)
          .updateOwnProfile(<String, dynamic>{'headline': 'new'});

      expect(service.lastUpdateUserId, 'u-1');
      expect(service.lastUpdatePatch, <String, dynamic>{'headline': 'new'});

      // Invalidating profileProvider triggers a re-fetch on the next read.
      await container.read(profileProvider.future);
      expect(
        runner.calls,
        greaterThan(callsBefore),
        reason: 'profileProvider must be invalidated post-update',
      );
    });

    test('updateOwnProfile is a no-op when there is no session', () async {
      final FakeAuthGateway auth = FakeAuthGateway(); // no session
      final _FakeQueryRunner runner = _FakeQueryRunner(null);
      final _FakeProfileService service = _FakeProfileService();
      final ProviderContainer container =
          _makeContainer(auth: auth, runner: runner, service: service);
      addTearDown(container.dispose);

      await container.read(ownProfileControllerProvider.future);
      await container
          .read(ownProfileControllerProvider.notifier)
          .updateOwnProfile(<String, dynamic>{'headline': 'x'});

      expect(
        service.lastUpdatePatch,
        isNull,
        reason: 'no session → must not hit the service',
      );
    });

    test('togglePrivateMode forwards to setPrivateMode and invalidates',
        () async {
      final FakeAuthGateway auth = FakeAuthGateway();
      auth.pushAuthState(
          AuthChangeEvent.initialSession, fakeSession(id: 'u-1'),);
      final _FakeQueryRunner runner = _FakeQueryRunner(<String, dynamic>{
        'id': 'u-1',
        'onboarded': true,
        'private_mode': false,
      });
      final _FakeProfileService service = _FakeProfileService();
      final ProviderContainer container =
          _makeContainer(auth: auth, runner: runner, service: service);
      addTearDown(container.dispose);

      await container.read(ownProfileControllerProvider.future);
      final int callsBefore = runner.calls;

      await container
          .read(ownProfileControllerProvider.notifier)
          .togglePrivateMode(true);

      expect(service.lastPrivateMode, isTrue);
      await container.read(profileProvider.future);
      expect(runner.calls, greaterThan(callsBefore));
    });

    test('refresh invalidates the underlying provider', () async {
      final FakeAuthGateway auth = FakeAuthGateway();
      auth.pushAuthState(
          AuthChangeEvent.initialSession, fakeSession(id: 'u-1'),);
      final _FakeQueryRunner runner = _FakeQueryRunner(<String, dynamic>{
        'id': 'u-1',
        'onboarded': true,
      });
      final _FakeProfileService service = _FakeProfileService();
      final ProviderContainer container =
          _makeContainer(auth: auth, runner: runner, service: service);
      addTearDown(container.dispose);

      await container.read(ownProfileControllerProvider.future);
      final int callsBefore = runner.calls;

      await container.read(ownProfileControllerProvider.notifier).refresh();

      expect(runner.calls, greaterThan(callsBefore));
    });
  });
}
