import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/settings/presentation/widgets/tab_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('TabBadge hidden when count=0', (WidgetTester tester) async {
    await tester.pumpWidget(host(const TabBadge(count: 0)));
    expect(find.byType(TabBadge), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('TabBadge shows numeric count up to 99',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const TabBadge(count: 42)));
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('TabBadge caps at 99+ when count > 99',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const TabBadge(count: 150)));
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('TabBadge uses gold bg + navy text',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(const TabBadge(count: 7)));
    final Container container = tester.widget<Container>(
      find.byKey(const Key('tab_badge.container')),
    );
    final BoxDecoration deco = container.decoration! as BoxDecoration;
    expect(deco.color, const Color(0xFFFFC107));
    final Text text = tester.widget<Text>(find.text('7'));
    expect(text.style?.color, const Color(0xFF0F3460));
  });
}
