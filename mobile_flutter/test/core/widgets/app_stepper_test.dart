import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppStepper displays value + suffix', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppStepper(value: 5, suffix: ' min', onChanged: (_) {}),
        ),
      ),
    );
    expect(find.text('5 min'), findsOneWidget);
  });

  testWidgets('AppStepper increments and decrements', (tester) async {
    var v = 2;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: AppStepper(
              value: v,
              onChanged: (next) => setState(() => v = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Increment'));
    await tester.pumpAndSettle();
    expect(v, 3);
    await tester.tap(find.bySemanticsLabel('Decrement'));
    await tester.pumpAndSettle();
    expect(v, 2);
  });

  testWidgets('AppStepper disables - at min and + at max', (tester) async {
    var v = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: AppStepper(
              value: v,
              min: 0,
              max: 2,
              onChanged: (next) => setState(() => v = next),
            ),
          ),
        ),
      ),
    );
    // At min — tapping minus does nothing.
    await tester.tap(find.bySemanticsLabel('Decrement'));
    await tester.pumpAndSettle();
    expect(v, 0);

    // Bump to max.
    await tester.tap(find.bySemanticsLabel('Increment'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Increment'));
    await tester.pumpAndSettle();
    expect(v, 2);

    // At max — tapping plus does nothing.
    await tester.tap(find.bySemanticsLabel('Increment'));
    await tester.pumpAndSettle();
    expect(v, 2);
  });
}
