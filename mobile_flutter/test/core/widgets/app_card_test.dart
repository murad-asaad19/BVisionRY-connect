import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppCard renders its child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: AppCard(child: Text('Hello card')),
        ),
      ),
    );
    expect(find.text('Hello card'), findsOneWidget);
  });

  testWidgets('AppCard fires onTap when pressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tap me'));
    expect(tapped, isTrue);
  });

  testWidgets('AppCard featured variant uses gold border + goldPale gradient',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: AppCard(
            variant: AppCardVariant.featured,
            child: Text('Premium'),
          ),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('app-card-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    final border = decoration.border! as Border;
    expect(border.top.width, 1.5);
    expect(border.top.color, const Color(0xFFFFC107));
  });
}
