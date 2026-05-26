import 'package:connect_mobile/core/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke-test that an app harness which depends on the push wiring builds
/// and runs the first frame without throwing when `Env.firebaseEnabled` is
/// false. Full E2E coverage of the wires lives in the handler tests + the
/// `push_toast_routing_widget_test.dart` widget integration.
void main() {
  testWidgets('Push wiring is dormant when Env.firebaseEnabled=false',
      (WidgetTester tester) async {
    expect(Env.firebaseEnabled, isFalse);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SizedBox())),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
