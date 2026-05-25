import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/presentation/about_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('AboutStep — fully populated', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await OnboardingDraftRepository(prefs).write(const OnboardingDraft(
      goalText: 'Hiring a fractional design lead for our healthtech app.',
      goalType: GoalType.hire,
      name: 'Ada Lovelace',
      handle: 'ada',
      roles: <String>['founder'],
      primaryRole: 'founder',
      city: 'Berlin',
      country: 'Germany',
      headline: 'Healthtech founder',
      bio: 'Building privacy-first mental wellness tools. Hiring design talent.',
    ));

    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          onboardingDraftRepositoryProvider
              .overrideWith((_) async => OnboardingDraftRepository(prefs)),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          currentSessionProvider.overrideWithValue(fakeSession(id: 'user-1')),
        ],
        child: const AboutStep(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(414, 1100),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'onboarding_about_step_filled');
  });
}
