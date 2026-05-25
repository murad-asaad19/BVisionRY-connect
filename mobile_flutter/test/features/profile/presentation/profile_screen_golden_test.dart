import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/auth/providers/profile_provider.dart';
import 'package:connect_mobile/features/profile/data/profile_signals_service.dart';
import 'package:connect_mobile/features/profile/domain/profile.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:connect_mobile/features/profile/presentation/profile_screen.dart';
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

class _FakeSignalsService implements ProfileSignalsService {
  @override
  Future<ProfileSignals> fetchSignals(String targetUserId) async =>
      ProfileSignals.empty;
}

Profile _omar() => Profile.fromJson(<String, dynamic>{
      'id': 'u-1',
      'handle': 'omar-d',
      'name': 'Omar Daher',
      'headline': 'Senior backend, ex-Stripe',
      'bio': 'Pre-seed founder building B2B fintech for SMEs.',
      'roles': <String>['builder', 'advisor'],
      'primary_role': 'builder',
      'city': 'London',
      'country': 'UK',
      'goal_type': 'hire',
      'goal_text': 'Co-found or join a pre-seed B2B SaaS as fractional CTO.',
      'goal_updated_at': DateTime.now().toUtc().toIso8601String(),
      'photo_url': null,
      'onboarded': true,
      'verified_github_username': 'omar-d',
      'verified_github_id': 1,
      'verified_at': '2026-01-01T09:00:00Z',
      'suspended_at': null,
      'private_mode': false,
      'read_receipts_enabled': false,
      'public_investor_page': false,
      'created_at': '2026-01-01T09:00:00Z',
      'updated_at': '2026-04-01T09:00:00Z',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('ProfileScreen — full onboarded profile', (
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
            (Ref<AsyncValue<Profile?>> _) async => _omar(),
          ),
          profileSignalsServiceProvider
              .overrideWithValue(_FakeSignalsService()),
        ],
        child: const ProfileScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 1100),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'profile_screen_full');
  });
}
