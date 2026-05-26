// Phase 15 — block integration flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ana blocks Bruno from his public profile', (tester) async {
    if (!isSeedEnabled) {
      markTestSkipped('SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL not provided');
      return;
    }
    await bootApp(tester);
    await signInAs(tester, TestUsers.ana);
    await tester.tap(find.byKey(const Key('tab-network')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(TestUsers.bruno.displayName).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-block')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('profile-send-intro')), findsNothing);
  });
}
