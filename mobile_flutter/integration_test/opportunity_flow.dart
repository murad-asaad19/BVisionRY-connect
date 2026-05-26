// Phase 15 — opportunity create + interest integration flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bruno creates an opportunity, Ana expresses interest',
      (tester) async {
    if (!isSeedEnabled) {
      markTestSkipped('SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL not provided');
      return;
    }
    await bootApp(tester);
    await signInAs(tester, TestUsers.bruno);
    await tester.tap(find.byKey(const Key('tab-opportunities')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-opportunity')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('opportunity-title')),
      'Looking for a Rust engineer',
    );
    await tester.tap(find.byKey(const Key('opportunity-publish')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Looking for a Rust engineer'), findsOneWidget);
  });
}
