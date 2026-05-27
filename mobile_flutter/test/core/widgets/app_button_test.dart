import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton fires onPressed and shows label', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppButton(
            label: 'Send intro',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Send intro'));
    expect(pressed, isTrue);
  });

  testWidgets('AppButton.disabled does not call onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppButton(
            label: 'X',
            onPressed: () => pressed = true,
            disabled: true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('X'));
    expect(pressed, isFalse);
  });

  testWidgets('AppButton renders gold variant with navy text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppButton(
            label: 'Go',
            variant: AppButtonVariant.gold,
            onPressed: () {},
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Go'));
    expect(text.style?.color, const Color(0xFF0F3460));
  });

  testWidgets('AppButton with null onPressed collapses to disabled visual',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: AppButton(label: 'Next', variant: AppButtonVariant.gold),
        ),
      ),
    );
    // Gold variant uses navy text; disabled variant uses white text. If
    // null onPressed correctly collapses to disabled, fg becomes white.
    final text = tester.widget<Text>(find.text('Next'));
    expect(text.style?.color, const Color(0xFFFFFFFF));
  });

  testWidgets('AppButton loading shows progress and ignores tap',
      (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppButton(
            label: 'Send',
            onPressed: () => pressed = true,
            loading: true,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Send'));
    expect(pressed, isFalse);
  });
}
