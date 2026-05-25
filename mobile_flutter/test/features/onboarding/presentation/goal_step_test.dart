import 'package:connect_mobile/features/onboarding/data/infer_goal_service.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/presentation/goal_step.dart';
import 'package:connect_mobile/features/onboarding/providers/onboarding_draft_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump.dart';

/// Hand-rolled fake so we don't have to mocktail the [InferGoalService] —
/// every test wants to capture the call args anyway.
class _FakeInferService implements InferGoalService {
  _FakeInferService(this._answer);
  final Future<InferGoalResult> Function({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) _answer;

  int calls = 0;
  String? lastText;
  String? lastPrimaryRole;
  List<String>? lastRoles;

  @override
  Future<InferGoalResult> infer({
    required String text,
    String? primaryRole,
    List<String>? roles,
  }) {
    calls++;
    lastText = text;
    lastPrimaryRole = primaryRole;
    lastRoles = roles;
    return _answer(text: text, primaryRole: primaryRole, roles: roles);
  }
}

InferGoalResult _high(GoalType g) =>
    InferGoalResult(goalType: g, confidence: InferConfidence.high);
InferGoalResult _low() => const InferGoalResult(
      goalType: null,
      confidence: InferConfidence.low,
    );

Future<Widget> _renderGoalStep({
  required InferGoalService svc,
  required SharedPreferences prefs,
}) async {
  return wrapWithTheme(
    child: const GoalStep(),
    overrides: <Override>[
      onboardingDraftRepositoryProvider
          .overrideWith((_) async => OnboardingDraftRepository(prefs)),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
      inferGoalServiceProvider.overrideWithValue(svc),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets(
    'typing >= 20 chars triggers debounced inference and auto-selects '
    'chip on high confidence',
    (WidgetTester tester) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _FakeInferService svc = _FakeInferService(
        ({required String text, String? primaryRole, List<String>? roles}) async =>
            _high(GoalType.hire),
      );
      await pumpWithI18n(
        tester,
        await _renderGoalStep(svc: svc, prefs: prefs),
      );

      await tester.enterText(
        find.byType(TextField),
        'I want to hire a designer for an app',
      );
      // Wait past the 800ms debounce + microtasks for state to update.
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      expect(svc.calls, 1);
      expect(svc.lastText, 'I want to hire a designer for an app');

      // Auto-select happened: draft.goalType == hire.
      final OnboardingDraft draft = await OnboardingDraftRepository(prefs).read() ??
          const OnboardingDraft();
      expect(draft.goalType, GoalType.hire);
    },
  );

  testWidgets('does NOT call infer when text < 20 chars',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          _high(GoalType.hire),
    );
    await pumpWithI18n(
      tester,
      await _renderGoalStep(svc: svc, prefs: prefs),
    );

    await tester.enterText(find.byType(TextField), 'too short');
    await tester.pump(const Duration(milliseconds: 900));

    expect(svc.calls, 0);
  });

  testWidgets('low confidence does NOT auto-select chip',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          _low(),
    );
    await pumpWithI18n(
      tester,
      await _renderGoalStep(svc: svc, prefs: prefs),
    );

    await tester.enterText(
      find.byType(TextField),
      'vague text that is long enough now',
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    final OnboardingDraft draft = await OnboardingDraftRepository(prefs).read() ??
        const OnboardingDraft();
    expect(draft.goalType, isNull);
  });

  testWidgets('Next button disabled until text valid + chip chosen',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          _low(),
    );
    await pumpWithI18n(
      tester,
      await _renderGoalStep(svc: svc, prefs: prefs),
    );

    // Initially disabled: the button's InkWell.onTap is null.
    final Finder btn = find.byKey(const ValueKey<String>('goal-next'));
    expect(btn, findsOneWidget);
    InkWell ink = tester.widget<InkWell>(
      find.descendant(of: btn, matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNull);
  });

  testWidgets('counter renders count/max', (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          _low(),
    );
    await pumpWithI18n(
      tester,
      await _renderGoalStep(svc: svc, prefs: prefs),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    // AppInput renders an internal counter "5/280".
    expect(find.textContaining('5/280'), findsWidgets);
  });

  testWidgets('tapping a chip manually sets goal type',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeInferService svc = _FakeInferService(
      ({required String text, String? primaryRole, List<String>? roles}) async =>
          _low(),
    );
    await pumpWithI18n(
      tester,
      await _renderGoalStep(svc: svc, prefs: prefs),
    );

    // Tap the "co_found" chip by key.
    await tester.tap(find.byKey(const ValueKey<String>('goal-chip-co_found')));
    await tester.pumpAndSettle();

    final OnboardingDraft draft = await OnboardingDraftRepository(prefs).read() ??
        const OnboardingDraft();
    expect(draft.goalType, GoalType.coFound);
  });
}
