// Phase 15 — send-intro integration flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ana sends a direct intro to Bruno', (tester) async {
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
    await tester.tap(find.byKey(const Key('profile-send-intro')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('intro-note-input')),
      'Hey Bruno — I noticed you also work on distributed systems. Would '
      'love 15 minutes to compare notes on Raft leader election under '
      'network partitions.',
    );
    await tester.tap(find.byKey(const Key('intro-send-cta')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('sent', findRichText: true), findsOneWidget);
  });
}
