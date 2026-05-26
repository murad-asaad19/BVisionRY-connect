// Phase 15 — image-message integration flow.
//
// Requires `imagePickerProvider` + storage upload to be overridden with
// mock implementations returning a bundled fixture asset.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ana picks and sends an image in chat', (tester) async {
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
    await tester.tap(find.byKey(const Key('chat-composer-image')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const Key('image-bubble')), findsAtLeastNWidgets(1));
  });
}
