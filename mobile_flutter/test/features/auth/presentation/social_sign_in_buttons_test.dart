import 'package:connect_mobile/features/auth/presentation/social_sign_in_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  testWidgets('fires onApple and onGoogle independently', (
    WidgetTester tester,
  ) async {
    bool apple = false;
    bool google = false;
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
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

  testWidgets('shows two spinners when both providers are loading',
      (WidgetTester tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: SocialSignInButtons(
            onApple: null,
            onGoogle: null,
            appleLoading: true,
            googleLoading: true,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
  });

  testWidgets('shows a single spinner on the loading provider only',
      (WidgetTester tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          body: SocialSignInButtons(
            onApple: () {},
            onGoogle: () {},
            googleLoading: true,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
