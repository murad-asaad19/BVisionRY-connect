import 'package:connect_mobile/features/onboarding/data/onboarding_draft_repository.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:connect_mobile/features/onboarding/presentation/roles_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/pump.dart';

Future<Widget> _renderRolesStep(SharedPreferences prefs) async {
  return wrapWithTheme(
    child: const RolesStep(),
    overrides: <Override>[
      onboardingDraftRepositoryProvider
          .overrideWith((_) async => OnboardingDraftRepository(prefs)),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
    ],
  );
}

Future<OnboardingDraft> _readDraft(SharedPreferences prefs) async {
  return await OnboardingDraftRepository(prefs).read() ??
      const OnboardingDraft();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('tapping role chips toggles selection',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await pumpWithI18n(tester, await _renderRolesStep(prefs));

    await tester.tap(find.byKey(const ValueKey<String>('role-chip-founder')));
    await tester.pumpAndSettle();
    expect((await _readDraft(prefs)).roles, <String>['founder']);

    await tester.tap(find.byKey(const ValueKey<String>('role-chip-leader')));
    await tester.pumpAndSettle();
    expect((await _readDraft(prefs)).roles, <String>['founder', 'leader']);

    // Toggling founder off removes it from the list.
    await tester.tap(find.byKey(const ValueKey<String>('role-chip-founder')));
    await tester.pumpAndSettle();
    expect((await _readDraft(prefs)).roles, <String>['leader']);
  });

  testWidgets('primary selector lists only selected roles',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await pumpWithI18n(tester, await _renderRolesStep(prefs));

    await tester.tap(find.byKey(const ValueKey<String>('role-chip-founder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('role-chip-investor')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('primary-pill-founder')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('primary-pill-investor')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('primary-pill-builder')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('primary-pill-leader')),
        findsNothing);
  });

  testWidgets('deselecting the primary role auto-clears primary',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await pumpWithI18n(tester, await _renderRolesStep(prefs));

    await tester.tap(find.byKey(const ValueKey<String>('role-chip-founder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('primary-pill-founder')));
    await tester.pumpAndSettle();
    expect((await _readDraft(prefs)).primaryRole, 'founder');

    // Untoggle founder: notifier should clear primary.
    await tester.tap(find.byKey(const ValueKey<String>('role-chip-founder')));
    await tester.pumpAndSettle();
    expect((await _readDraft(prefs)).primaryRole, isNull);
  });

  testWidgets('Next disabled without >=1 role + primary',
      (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await pumpWithI18n(tester, await _renderRolesStep(prefs));

    final Finder btn = find.byKey(const ValueKey<String>('roles-next'));
    InkWell ink = tester.widget<InkWell>(
      find.descendant(of: btn, matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNull);

    // Pick one role — still disabled (no primary yet).
    await tester.tap(find.byKey(const ValueKey<String>('role-chip-builder')));
    await tester.pumpAndSettle();
    ink = tester.widget<InkWell>(
      find.descendant(of: btn, matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNull);

    // Pick primary — now enabled.
    await tester.tap(find.byKey(const ValueKey<String>('primary-pill-builder')));
    await tester.pumpAndSettle();
    ink = tester.widget<InkWell>(
      find.descendant(of: btn, matching: find.byType(InkWell)),
    );
    expect(ink.onTap, isNotNull);
  });
}
