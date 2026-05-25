import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Pill renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: Pill(label: 'Active')),
      ),
    );
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('Pill navy variant has navy background + white text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: Pill(label: 'Founder', variant: PillVariant.navy),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('pill-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF0F3460));
    final text = tester.widget<Text>(find.text('Founder'));
    expect(text.style?.color, const Color(0xFFFFFFFF));
  });

  testWidgets('Pill outline variant has navy border', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: Pill(label: 'Outline', variant: PillVariant.outline),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('pill-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('Pill success variant uses intent palette', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: Pill(label: 'OK', variant: PillVariant.success),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('pill-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFDCFCE7));
  });
}
