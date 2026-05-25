import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SectionCard uppercases title and renders child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SectionCard(
            title: 'About',
            child: Text('Body text'),
          ),
        ),
      ),
    );
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('Body text'), findsOneWidget);
  });

  testWidgets('SectionCard without title only renders body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: SectionCard(child: Text('only body'))),
      ),
    );
    expect(find.text('only body'), findsOneWidget);
  });

  testWidgets('SectionCard has white bg + border decoration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SectionCard(title: 'X', child: SizedBox()),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('section-card-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFFFFFF));
    expect(decoration.border, isNotNull);
  });
}
