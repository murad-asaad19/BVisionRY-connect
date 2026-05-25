import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/auth/presentation/social_sign_in_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fires onApple and onGoogle independently', (
    WidgetTester tester,
  ) async {
    bool apple = false;
    bool google = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: SocialSignInButtons(
            onApple: () => apple = true,
            onGoogle: () => google = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('apple-sso')));
    await tester.tap(find.byKey(const Key('google-sso')));
    expect(apple, isTrue);
    expect(google, isTrue);
  });

  testWidgets('shows two spinners when loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SocialSignInButtons(
            onApple: null,
            onGoogle: null,
            loading: true,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
  });
}
