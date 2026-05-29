import 'dart:typed_data';

import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/profile/data/avatar_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/pump.dart';

class _NoRowRunner implements ProfileQueryRunner {
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => null;
}

class _FakeAvatarService extends AvatarUploadService {
  _FakeAvatarService()
      : super(source: _NullSource(), storage: _NullStorage(), userId: 'u-1');
}

class _NullSource implements AvatarSource {
  @override
  Future<Uint8List?> pickAndCropSquareAvatar({
    ImageSource source = ImageSource.gallery,
  }) async =>
      null;
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
  @override
  Future<void> clearPhotoUrl({required String userId}) async {}
}

Profile _base() => Profile.fromJson(<String, dynamic>{
      'id': 'u-1',
      'handle': 'sara-k',
      'name': 'Sara K',
      'headline': 'Existing headline value',
      'bio':
          'Existing bio that is long enough — building B2B fintech rails for SMEs.',
      'roles': <String>['founder'],
      'primary_role': 'founder',
      'city': 'Beirut',
      'country': 'LB',
      'goal_type': 'hire',
      'goal_text': 'Looking to hire a senior backend engineer for payments.',
      'goal_updated_at': '2026-04-01T09:00:00Z',
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('ProfileEditScreen — prefilled form', (
    WidgetTester tester,
  ) async {
    final loader = await primedLocaleLoader();
    final FakeAuthGateway auth = FakeAuthGateway();
    auth.pushAuthState(AuthChangeEvent.initialSession, fakeSession(id: 'u-1'));
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider
              .overrideWithValue(ProfileRepository(_NoRowRunner())),
          profileProvider.overrideWith(
            (Ref<AsyncValue<Profile?>> _) async => _base(),
          ),
          avatarUploadServiceProvider.overrideWith(
            (Ref<AvatarUploadService> _) => _FakeAvatarService(),
          ),
        ],
        child: const ProfileEditScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 1600),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'profile_edit_screen_prefilled');
  });
}
