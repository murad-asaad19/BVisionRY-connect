import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppIconButton fires onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppIconButton(
            icon: Icons.search,
            label: 'Search',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    expect(pressed, isTrue);
  });

  testWidgets('AppIconButton subtle variant draws a goldPale circle bg',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppIconButton(
            icon: Icons.add,
            label: 'Add',
            variant: AppIconButtonVariant.subtle,
            onPressed: () {},
          ),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('app-icon-button-frame')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFFF8E1));
  });

  testWidgets('AppIconButton size sm has 44dp hitbox via Material InkResponse',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppIconButton(
            icon: Icons.close,
            label: 'Close',
            size: AppIconButtonSize.sm,
            onPressed: () {},
          ),
        ),
      ),
    );
    // The outer SizedBox enforces the minimum touch target.
    final size =
        tester.getSize(find.byKey(const ValueKey('app-icon-button-hit')));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });
}
