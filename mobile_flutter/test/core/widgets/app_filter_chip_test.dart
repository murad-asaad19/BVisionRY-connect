import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppFilterChip shows label and count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppFilterChip(
            label: 'Mentors',
            active: false,
            onTap: () {},
            count: 12,
          ),
        ),
      ),
    );
    expect(find.text('Mentors (12)'), findsOneWidget);
  });

  testWidgets('AppFilterChip fires onTap when pressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppFilterChip(
            label: 'All',
            active: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('All'));
    expect(tapped, isTrue);
  });

  testWidgets('AppFilterChip active uses navy background + white text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppFilterChip(label: 'On', active: true, onTap: () {}),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('app-filter-chip-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF0F3460));
    final text = tester.widget<Text>(find.text('On'));
    expect(text.style?.color, const Color(0xFFFFFFFF));
  });
}
