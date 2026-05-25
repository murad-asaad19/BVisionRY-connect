import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/progress_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProgressDots renders total dots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: ProgressDots(total: 5, current: 2)),
      ),
    );
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('progress-dot-$i')), findsOneWidget);
    }
  });

  testWidgets('ProgressDots paints past=navy current=gold pending=border',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: ProgressDots(total: 3, current: 1)),
      ),
    );
    final past = tester.widget<Container>(
      find.byKey(const ValueKey('progress-dot-0')),
    );
    final current = tester.widget<Container>(
      find.byKey(const ValueKey('progress-dot-1')),
    );
    final pending = tester.widget<Container>(
      find.byKey(const ValueKey('progress-dot-2')),
    );

    expect(
      (past.decoration! as BoxDecoration).color,
      const Color(0xFF0F3460), // navy
    );
    expect(
      (current.decoration! as BoxDecoration).color,
      const Color(0xFFFFC107), // gold
    );
    expect(
      (pending.decoration! as BoxDecoration).color,
      const Color(0xFFE5E7EB), // border
    );
  });
}
