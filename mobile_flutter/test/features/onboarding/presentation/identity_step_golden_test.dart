import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/presentation/identity_step.dart';
import 'package:connect_mobile/features/onboarding/providers/handle_availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump.dart';

class _AvailableRunner implements HandleAvailabilityRunner {
  @override
  Future<bool> check(String handle) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('IdentityStep — filled state with handle hint',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await OnboardingDraftRepository(prefs).write(const OnboardingDraft(
      name: 'Ada Lovelace',
      handle: 'ada',
    ));

    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          onboardingDraftRepositoryProvider
              .overrideWith((_) async => OnboardingDraftRepository(prefs)),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          handleAvailabilityRunnerProvider.overrideWithValue(_AvailableRunner()),
        ],
        child: const IdentityStep(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(414, 896),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'onboarding_identity_step_filled');
  });
}
