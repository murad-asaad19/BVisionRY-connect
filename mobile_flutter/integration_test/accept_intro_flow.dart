// Phase 15 — accept-intro integration flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Bruno accepts Ana's intro and lands in chat", (tester) async {
    if (!isSeedEnabled) {
      markTestSkipped('SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL not provided');
      return;
    }
    await bootApp(tester);
    // The "send_intro_flow" test seeds an intro; in CI we run that flow
    // first to set up the inbox state. Locally, an intro must be present
    // for this assertion to pass.
    await signInAs(tester, TestUsers.bruno);

    await tester.tap(find.byKey(const Key('tab-inbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(TestUsers.ana.displayName).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('intro-accept')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const Key('chat-screen')), findsOneWidget);
  });
}
