import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/supabase/supabase_client.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/domain/daily_match.dart';
import 'package:connect_mobile/features/discovery/domain/discovery_profile.dart';
import 'package:connect_mobile/features/home/presentation/home_screen.dart';
import 'package:connect_mobile/features/intros/providers/warm_intros_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../helpers/fake_discovery_service.dart';
import '../../../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    registerDiscoveryFallbacks();
  });
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testGoldens('HomeScreen — thin pool (1 match)', (tester) async {
    final loader = await primedLocaleLoader();
    final fake = FakeDiscoveryService();
    when(() => fake.markMatchViewed(any())).thenAnswer((_) async {});
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer(
      (_) async => <DailyMatch>[
        DailyMatch(
          id: 'only',
          pickUserId: 'u-only',
          matchReason: 'Complementary goals',
          forDateLocal: DateTime.utc(2026, 4, 28),
          createdAt: DateTime.utc(2026, 4, 28, 4),
          profile: const DiscoveryProfile(
            id: 'u-only',
            handle: 'reema',
            name: 'Reema Saleh',
            primaryRole: 'investor',
            city: 'Manama',
            country: 'BH',
            headline: r'Angel · $50–250k · MENA agritech',
          ),
        ),
      ],
    );
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          discoveryServiceProvider.overrideWithValue(fake),
          supabaseInitProvider.overrideWith((_) async {}),
          warmSuggestionsProvider.overrideWith((_) async => const []),
        ],
        child: const HomeScreen(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 844),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'home_screen_thin_pool');
  });
}
