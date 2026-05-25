import 'dart:typed_data';

import 'package:connect_mobile/core/routing/routes.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/profile/data/avatar_upload_service.dart';
import 'package:connect_mobile/features/profile/data/profile_service.dart';
import 'package:connect_mobile/features/profile/data/profile_signals_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:connect_mobile/features/profile/presentation/profile_edit_screen.dart';
import 'package:connect_mobile/features/profile/presentation/profile_screen.dart';
import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_supabase.dart';
import '../../helpers/pump.dart';

class _NoRowRunner implements ProfileQueryRunner {
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => null;
}

class _RecordingProfileService extends ProfileService {
  _RecordingProfileService(this._next) : super(_StubGateway());
  final Profile _next;
  Map<String, dynamic>? lastPatch;
  @override
  Future<Profile> updateProfile({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    lastPatch = patch;
    return _next;
  }
}

class _StubGateway implements ProfileGateway {
  @override
  Future<Map<String, dynamic>?> fetchById(String id) async => null;
  @override
  Future<Map<String, dynamic>> updateById({
    required String id,
    required Map<String, dynamic> patch,
  }) async =>
      <String, dynamic>{};
  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) async =>
      null;
  @override
  Future<FunctionResponse> invokeFunction(String name, {Object? body}) async =>
      throw UnimplementedError();
}

class _FakeSignalsService implements ProfileSignalsService {
  @override
  Future<ProfileSignals> fetchSignals(String targetUserId) async =>
      ProfileSignals.empty;
}

class _FakeAvatarService extends AvatarUploadService {
  _FakeAvatarService()
      : super(source: _NullSource(), storage: _NullStorage(), userId: 'u-1');
}

class _NullSource implements AvatarSource {
  @override
  Future<Uint8List?> pickAndCropSquareAvatar() async => null;
}

class _NullStorage implements AvatarStorageGateway {
  @override
  Future<void> uploadAvatar({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {}
  @override
  String getPublicUrl(String path) => 'https://cdn/$path';
  @override
  Future<void> patchPhotoUrl({
    required String userId,
    required String url,
  }) async {}
}

Profile _initial() => Profile.fromJson(<String, dynamic>{
      'id': 'u-1',
      'handle': 'sara-k',
      'name': 'Sara K',
      'headline': 'Old headline value goes here',
      'bio': 'Existing bio that is long enough.',
      'roles': <String>['founder'],
      'primary_role': 'founder',
      'city': 'Beirut',
      'country': 'LB',
      'goal_type': 'hire',
      'goal_text': 'Looking to hire a backend engineer.',
      'goal_updated_at': DateTime.now().toUtc().toIso8601String(),
      'photo_url': null,
      'onboarded': true,
      'verified_github_username': null,
      'verified_github_id': null,
      'verified_at': null,
      'suspended_at': null,
      'private_mode': false,
      'read_receipts_enabled': false,
      'public_investor_page': false,
      'created_at': '2026-01-01T09:00:00Z',
      'updated_at': '2026-04-01T09:00:00Z',
    });

void main() {
  testWidgets(
    'e2e: /profile → tap edit → change headline → save → returns to /profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final LocaleLoader loader = await primedLocaleLoader();
      final Profile starting = _initial();
      final Profile updated = starting.copyWith(headline: 'Brand new headline');

      final _RecordingProfileService svc = _RecordingProfileService(updated);
      bool fetched = false;

      final GoRouter router = GoRouter(
        initialLocation: Routes.profile,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: Routes.profileEdit,
            builder: (_, __) => const ProfileEditScreen(),
          ),
        ],
      );

      final FakeAuthGateway auth = FakeAuthGateway();
      auth.pushAuthState(
        AuthChangeEvent.initialSession,
        fakeSession(id: 'u-1'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            localeLoaderProvider.overrideWithValue(loader),
            authGatewayProvider.overrideWithValue(auth),
            profileRepositoryProvider
                .overrideWithValue(ProfileRepository(_NoRowRunner())),
            profileServiceProvider.overrideWithValue(svc),
            profileSignalsServiceProvider
                .overrideWithValue(_FakeSignalsService()),
            avatarUploadServiceProvider.overrideWith(
              (Ref<AvatarUploadService> _) => _FakeAvatarService(),
            ),
            profileProvider.overrideWith((
              Ref<AsyncValue<Profile?>> _,
            ) async {
              if (!fetched) {
                fetched = true;
                return starting;
              }
              return updated;
            }),
          ],
          child: MaterialApp.router(
            theme: buildAppTheme(Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Land on /profile, asserts the old headline is shown.
      expect(find.text('Old headline value goes here'), findsOneWidget);

      // Tap edit → /profile/edit.
      await tester.tap(find.byKey(const Key('profileScreen.editButton')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('profileEdit.save')),
        findsOneWidget,
        reason: 'edit form mounted',
      );

      // Change the headline and save.
      await tester.enterText(
        find.byKey(const Key('profileEdit.headline')),
        'Brand new headline',
      );
      await tester.tap(find.byKey(const Key('profileEdit.save')));
      await tester.pumpAndSettle();

      // The service saw the patch.
      expect(svc.lastPatch?['headline'], 'Brand new headline');

      // After pop, ProfileScreen re-renders with the updated value.
      expect(find.text('Brand new headline'), findsOneWidget);
    },
  );
}
