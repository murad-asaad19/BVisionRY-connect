import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/onboarding/data/infer_goal_service.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/presentation/goal_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump.dart';

class _StubInferService implements InferGoalService {
  @override
  Future<InferGoalResult> infer({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) async {
    return const InferGoalResult(
      goalType: null,
      confidence: InferConfidence.low,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testGoldens('GoalStep — partially filled state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Seed a representative draft so the golden surfaces the chip-selected
    // state and a typical 30-ish char goal description.
    await OnboardingDraftRepository(prefs).write(const OnboardingDraft(
      goalText: 'Hiring a fractional design lead',
      goalType: GoalType.hire,
    ));

    final loader = await primedLocaleLoader();
    await tester.pumpWidgetBuilder(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          onboardingDraftRepositoryProvider
              .overrideWith((_) async => OnboardingDraftRepository(prefs)),
          sharedPreferencesProvider.overrideWith((_) async => prefs),
          inferGoalServiceProvider.overrideWithValue(_StubInferService()),
        ],
        child: const GoalStep(),
      ),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(414, 896),
    );
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'onboarding_goal_step_filled');
  });
}
