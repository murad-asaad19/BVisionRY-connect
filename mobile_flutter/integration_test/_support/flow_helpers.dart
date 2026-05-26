// Phase 15 — flow helpers used by every integration_test.
//
// Boots the app (via `lib/main.dart`), seeds the local Supabase stack,
// and exposes high-level navigation helpers used by every flow.

import 'package:connect_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';
import 'seed.dart';

/// Boots `app.main()` and waits for the first frame after Supabase init.
Future<void> bootApp(WidgetTester tester) async {
  await seedAll();
  await app.main();
  await tester.pumpAndSettle(const Duration(seconds: 4));
}

/// Drives the sign-in form for [user] and waits for the home tab.
Future<void> signInAs(WidgetTester tester, TestUser user) async {
  await tester.enterText(find.byKey(const Key('sign-in-email')), user.email);
  await tester.enterText(
    find.byKey(const Key('sign-in-password')),
    user.password,
  );
  await tester.tap(find.byKey(const Key('sign-in-submit')));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}
