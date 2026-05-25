import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/data/profile_repository.dart';
import 'package:connect_mobile/features/auth/providers/auth_service_provider.dart';
import 'package:connect_mobile/features/profile/data/public_profile_service.dart';
import 'package:connect_mobile/features/profile/presentation/public_profile_screen.dart';
import 'package:connect_mobile/features/profile/providers/public_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/pump.dart';

class _NoRowRunner implements ProfileQueryRunner {
  @override
  Future<Map<String, dynamic>?> selectById(String id) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('PublicProfileScreen — anon view', (WidgetTester tester) async {
    final loader = await primedLocaleLoader();
    final FakeAuthGateway auth = FakeAuthGateway();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          authGatewayProvider.overrideWithValue(auth),
          profileRepositoryProvider
              .overrideWithValue(ProfileRepository(_NoRowRunner())),
          publicProfileProvider('omar-d').overrideWith(
            (Ref<AsyncValue<PublicProfile?>> _) async => const PublicProfile(
              id: 'u-1',
              handle: 'omar-d',
              name: 'Omar Daher',
              headline:
                  'Senior backend, ex-Stripe · Open to fractional CTO work',
              primaryRole: 'builder',
              roles: <String>['builder'],
              city: 'London',
              country: 'United Kingdom',
              bio: 'Building B2B fintech rails for SMEs. Always happy to chat.',
              photoUrl: null,
              verifiedGithubUsername: 'omar-d',
            ),
          ),
        ],
        child: const PublicProfileScreen(handle: 'omar-d'),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 800),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'public_profile_screen_anon');
  });
}
