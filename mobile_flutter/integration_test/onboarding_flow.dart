// Phase 15 — 4-step onboarding integration flow.
//
// Carla is seeded as onboarded=false. After sign-in she should land on the
// onboarding stepper. Each step is gated on at least one form field.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new user completes 4-step onboarding', (tester) async {
    if (!isSeedEnabled) {
      markTestSkipped('SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL not provided');
      return;
    }
    await bootApp(tester);
    await signInAs(tester, TestUsers.carla);

    // Step 1: Goal
    await tester.enterText(
      find.byKey(const Key('onboarding-goal-input')),
      'I am looking to hire senior backend engineers with Rust experience.',
    );
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    // Step 2: Identity
    await tester.enterText(
      find.byKey(const Key('onboarding-handle')),
      'carla',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding-display-name')),
      'Carla Onboarded',
    );
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    // Step 3: Roles
    await tester.tap(find.byKey(const Key('role-chip-founder')));
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    // Step 4: About + finalize
    await tester.tap(find.byKey(const Key('onboarding-finalize')));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(find.text('Home'), findsOneWidget);
  });
}
