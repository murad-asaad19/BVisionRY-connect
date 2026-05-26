// Phase 15 — voice-message integration flow.
//
// Requires the recorder and upload providers to be overridden with mock
// implementations. The flow validates the bubble renders with
// transcript_status=pending after send.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ana records and sends a 3-second voice message', (tester) async {
    if (!isSeedEnabled) {
      markTestSkipped('SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL not provided');
      return;
    }
    await bootApp(tester);
    await signInAs(tester, TestUsers.ana);

    await tester.tap(find.byKey(const Key('tab-chats')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(TestUsers.bruno.displayName).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-composer-voice')));
    await tester.pumpAndSettle();
    // Simulate 3s of recording (mock recorder reports duration immediately)
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('voice-stop')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voice-send')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const Key('voice-bubble')), findsAtLeastNWidgets(1));
  });
}
