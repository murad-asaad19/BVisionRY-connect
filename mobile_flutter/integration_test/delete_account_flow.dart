// Phase 15 — delete-account integration flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ana deletes her account, lands on /sign-in', (tester) async {
    if (!isSeedEnabled) {
      markTestSkipped('SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL not provided');
      return;
    }
    await bootApp(tester);
    await signInAs(tester, TestUsers.ana);
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-delete-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-account-confirm-input')),
      'DELETE',
    );
    await tester.tap(find.byKey(const Key('delete-account-submit')));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
  });
}
