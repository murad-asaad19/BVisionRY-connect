import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/presentation/identity_step.dart';
import 'package:connect_mobile/features/onboarding/providers/handle_availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump.dart';

class _FakeRunner implements HandleAvailabilityRunner {
  _FakeRunner(this._answer);
  final Future<bool> Function(String handle) _answer;
  int calls = 0;
  String? lastHandle;

  @override
  Future<bool> check(String handle) async {
    calls++;
    lastHandle = handle;
    return _answer(handle);
  }
}

Future<Widget> _renderIdentityStep({
  required HandleAvailabilityRunner runner,
  required SharedPreferences prefs,
}) async {
  return wrapWithTheme(
    child: const IdentityStep(),
    overrides: <Override>[
      onboardingDraftRepositoryProvider
          .overrideWith((_) async => OnboardingDraftRepository(prefs)),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
      handleAvailabilityRunnerProvider.overrideWithValue(runner),
    ],
  );
}

/// Helper: simulate the user moving focus off the handle field. `enterText`
/// always focuses the field it types into, so unfocusing the primary focus
/// node fires AppInput's internal blur listener.
Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('typing a valid handle then blurring triggers availability RPC',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    await pumpWithI18n(
      tester,
      await _renderIdentityStep(runner: runner, prefs: prefs),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('identity-handle')),
      'ada',
    );
    await _blur(tester);

    expect(runner.calls, 1);
    expect(runner.lastHandle, 'ada');
  });

  testWidgets('shows X icon when handle is reported taken',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeRunner runner = _FakeRunner((String h) async => false);
    await pumpWithI18n(
      tester,
      await _renderIdentityStep(runner: runner, prefs: prefs),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('identity-handle')),
      'taken',
    );
    await _blur(tester);

    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('shows check icon when handle is reported available',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    await pumpWithI18n(
      tester,
      await _renderIdentityStep(runner: runner, prefs: prefs),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('identity-handle')),
      'ada',
    );
    await _blur(tester);

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('Next disabled until name + handle valid + available',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    await pumpWithI18n(
      tester,
      await _renderIdentityStep(runner: runner, prefs: prefs),
    );

    final Finder btn = find.byKey(const ValueKey<String>('identity-next'));
    InkWell ink = tester.widget<InkWell>(
      find.descendant(of: btn, matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNull, reason: 'starts disabled (empty)');

    await tester.enterText(
      find.byKey(const ValueKey<String>('identity-name')),
      'Ada',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('identity-handle')),
      'ada',
    );
    await _blur(tester);

    ink = tester.widget<InkWell>(
      find.descendant(of: btn, matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNotNull, reason: 'enabled once everything checks out');
  });

  testWidgets('invalid handle format does not call RPC on blur',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final _FakeRunner runner = _FakeRunner((String h) async => true);
    await pumpWithI18n(
      tester,
      await _renderIdentityStep(runner: runner, prefs: prefs),
    );

    // Uppercase fails the lowercase regex — should never reach the RPC.
    await tester.enterText(
      find.byKey(const ValueKey<String>('identity-handle')),
      'Ada',
    );
    await _blur(tester);

    expect(runner.calls, 0);
  });
}
