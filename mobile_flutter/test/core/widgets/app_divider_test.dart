import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppDivider renders a 1px horizontal line by default',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: AppDivider()),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('divider-line')),
    );
    expect(container.constraints?.maxHeight, 1);
  });

  testWidgets('AppDivider renders an inline label between two lines',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: AppDivider(label: 'OR')),
      ),
    );
    expect(find.text('OR'), findsOneWidget);
  });

  testWidgets('AppDivider vertical orientation renders a 1px column',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SizedBox(
            height: 40,
            child: AppDivider(orientation: Axis.vertical),
          ),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('divider-line')),
    );
    expect(container.constraints?.maxWidth, 1);
  });
}
