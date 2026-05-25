import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_banner.dart';
import 'package:connect_mobile/core/widgets/variants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppBanner shows title and body text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: AppBanner(
            intent: AppIntent.info,
            title: 'Heads up',
            child: Text('Some context'),
          ),
        ),
      ),
    );
    expect(find.text('Heads up'), findsOneWidget);
    expect(find.text('Some context'), findsOneWidget);
  });

  testWidgets('AppBanner close button fires onClose when tapped',
      (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppBanner(
            intent: AppIntent.warning,
            onClose: () => closed = true,
            child: const Text('Body'),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });

  testWidgets('AppBanner uses warning intent colors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: AppBanner(intent: AppIntent.warning, child: Text('!')),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('app-banner-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFEF3C7));
  });
}
