@Tags(<String>['integration'])
library;

import 'package:connect_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Lightweight smoke test that boots [HomeScreen] inside a [ProviderScope].
///
/// Marked with the `integration` tag so the default `flutter test` run
/// skips it; only `flutter test --tags integration` (or running the file
/// directly on a connected device) executes it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('boots HomeScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
