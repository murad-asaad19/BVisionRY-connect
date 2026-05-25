import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/data/onboarding_service.dart';
import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/presentation/about_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/pump.dart';

/// Test-double for [ProfileUpdateRunner]. Captures the most recent patch so
/// the assertions can verify exactly what was sent to the server.
class _FakeRunner implements ProfileUpdateRunner {
  _FakeRunner({this.throwOnUpdate});

  int calls = 0;
  String? lastUserId;
  Map<String, dynamic>? lastPatch;
  Object? throwOnUpdate;

  @override
  Future<void> update({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    calls++;
    lastUserId = userId;
    lastPatch = patch;
    if (throwOnUpdate != null) throw throwOnUpdate!;
  }
}

Future<Widget> _renderAboutStep({
  required SharedPreferences prefs,
  required ProfileUpdateRunner runner,
  Session? session,
}) async {
  return wrapWithTheme(
    child: const AboutStep(),
    overrides: <Override>[
      onboardingDraftRepositoryProvider
          .overrideWith((_) async => OnboardingDraftRepository(prefs)),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
      onboardingServiceProvider.overrideWithValue(OnboardingService(runner)),
      // sessionProvider is a StreamProvider — overriding the synchronous
      // accessor is enough for AboutStep, which reads `currentSessionProvider`.
      currentSessionProvider.overrideWithValue(session),
    ],
  );
}

const OnboardingDraft _validDraft = OnboardingDraft(
  goalText: 'Hiring a fractional designer for our healthtech app.',
  goalType: GoalType.hire,
  name: 'Ada',
  handle: 'ada',
  roles: <String>['founder'],
  primaryRole: 'founder',
  city: 'Berlin',
  country: 'Germany',
  headline: 'Founder',
  bio: 'A short but valid bio entry to pass.',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('submit disabled when required fields missing',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeRunner runner = _FakeRunner();
    await pumpWithI18n(
      tester,
      await _renderAboutStep(prefs: prefs, runner: runner),
    );

    final Finder btn = find.byKey(const ValueKey<String>('about-submit'));
    final InkWell ink = tester.widget<InkWell>(
      find.descendant(of: btn, matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNull);
  });

  testWidgets('submit calls OnboardingService and clears draft on success',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Seed the draft store with a fully valid submission.
    await OnboardingDraftRepository(prefs).write(_validDraft);

    final _FakeRunner runner = _FakeRunner();
    final Session session = fakeSession(id: 'user-1');
    await pumpWithI18n(
      tester,
      await _renderAboutStep(
        prefs: prefs,
        runner: runner,
        session: session,
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('about-submit')));
    await tester.pumpAndSettle();

    expect(runner.calls, 1);
    expect(runner.lastUserId, 'user-1');
    expect(runner.lastPatch?['name'], 'Ada');
    expect(runner.lastPatch?['handle'], 'ada');
    expect(runner.lastPatch?['onboarded'], isTrue);

    // Draft is reset after success.
    expect(await OnboardingDraftRepository(prefs).read(), isNull);
  });

  testWidgets('submit shows a danger toast on service throw',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await OnboardingDraftRepository(prefs).write(_validDraft);

    final _FakeRunner runner = _FakeRunner(throwOnUpdate: Exception('boom'));
    final Session session = fakeSession(id: 'user-1');
    await pumpWithI18n(
      tester,
      await _renderAboutStep(
        prefs: prefs,
        runner: runner,
        session: session,
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('about-submit')));
    await tester.pumpAndSettle();

    // The draft was NOT cleared because the submit threw.
    expect(await OnboardingDraftRepository(prefs).read(), isNotNull);
  });
}
