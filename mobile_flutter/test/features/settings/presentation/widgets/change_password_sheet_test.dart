import 'package:connect_mobile/core/widgets/app_button.dart';
import 'package:connect_mobile/features/settings/presentation/widgets/change_password_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets(
      'ChangePasswordSheet gates submit on current + ≥ 8 char new password',
      (WidgetTester tester) async {
    String? capturedCurrent;
    String? capturedNext;
    final Widget shell = await wrapWithTheme(
      child: Scaffold(
        body: ChangePasswordSheet(
          onSubmit: (String current, String next) async {
            capturedCurrent = current;
            capturedNext = next;
          },
        ),
      ),
    );
    await pumpWithI18n(tester, shell);

    final Finder btn = find.byKey(const Key('changePw.submit'));
    // Nothing entered → disabled.
    expect(tester.widget<AppButton>(btn).onPressed, isNull);

    // A valid new password alone is not enough — the current password gates it.
    await tester.enterText(
      find.byKey(const Key('changePw.input')),
      'verysecurepass',
    );
    await tester.pump();
    expect(tester.widget<AppButton>(btn).onPressed, isNull);

    // Current password present but new password too short → still disabled.
    await tester.enterText(
      find.byKey(const Key('changePw.currentInput')),
      'oldpassword',
    );
    await tester.enterText(find.byKey(const Key('changePw.input')), 'short');
    await tester.pump();
    expect(tester.widget<AppButton>(btn).onPressed, isNull);

    // Both valid → enabled.
    await tester.enterText(
      find.byKey(const Key('changePw.input')),
      'verysecurepass',
    );
    await tester.pump();
    expect(tester.widget<AppButton>(btn).onPressed, isNotNull);

    await tester.tap(btn);
    await tester.pumpAndSettle();
    expect(capturedCurrent, 'oldpassword');
    expect(capturedNext, 'verysecurepass');
  });
}
