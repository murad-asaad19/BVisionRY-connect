import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/profile/presentation/profile_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('ProfileHero — verified builder with two roles', (
    WidgetTester tester,
  ) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[localeLoaderProvider.overrideWithValue(loader)],
        child: const Material(
          child: ProfileHero(
            data: ProfileHeroData(
              name: 'Omar Daher',
              headline: 'Senior backend, ex-Stripe · Open to fractional CTO',
              city: 'London',
              country: 'UK',
              roles: <String>['builder', 'advisor'],
              primaryRole: 'builder',
              photoUrl: null,
              verified: true,
            ),
          ),
        ),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 320),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'profile_hero_verified');
  });

  testGoldens('ProfileHero — anon view (no badge, single role)', (
    WidgetTester tester,
  ) async {
    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[localeLoaderProvider.overrideWithValue(loader)],
        child: const Material(
          child: ProfileHero(
            data: ProfileHeroData(
              name: 'Sara Khalil',
              headline: 'Pre-seed founder building B2B fintech',
              city: 'Beirut',
              country: 'LB',
              roles: <String>['founder'],
              primaryRole: 'founder',
              photoUrl: null,
              verified: false,
            ),
          ),
        ),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(390, 320),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'profile_hero_anon');
  });
}
