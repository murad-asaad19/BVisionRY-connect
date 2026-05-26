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

DailyMatch _m(
  String id,
  String name, {
  required String role,
  required String city,
}) =>
    DailyMatch(
      id: id,
      pickUserId: 'u-$id',
      matchReason: 'Complementary goals',
      forDateLocal: DateTime.utc(2026, 4, 28),
      createdAt: DateTime.utc(2026, 4, 28, 4),
      profile: DiscoveryProfile(
        id: 'u-$id',
        handle: id,
        name: name,
        primaryRole: role,
        city: city,
        country: 'UK',
        headline: 'Senior backend, ex-Stripe',
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    registerDiscoveryFallbacks();
  });
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testGoldens('HomeScreen — 5 matches happy path', (tester) async {
    final loader = await primedLocaleLoader();
    final fake = FakeDiscoveryService();
    when(() => fake.markMatchViewed(any())).thenAnswer((_) async {});
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer(
      (_) async => <DailyMatch>[
        _m('omar', 'Omar Daher', role: 'builder', city: 'London'),
        _m('lina', 'Lina Maatouk', role: 'investor', city: 'Dubai'),
        _m('karim', 'Karim Adel', role: 'builder', city: 'Cairo'),
        _m('noor', 'Noor Hadi', role: 'founder', city: 'Riyadh'),
        _m('tomas', 'Tomas L.', role: 'leader', city: 'NYC'),
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
    await screenMatchesGolden(tester, 'home_screen_5_matches');
  });
}
