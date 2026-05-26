import 'package:connect_mobile/features/settings/presentation/widgets/change_password_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('ChangePasswordSheet gates submit on ≥ 8 char password',
      (WidgetTester tester) async {
    String? captured;
    final Widget shell = await wrapWithTheme(
      child: Scaffold(
        body: ChangePasswordSheet(
          onSubmit: (String pw) async => captured = pw,
        ),
      ),
    );
    await pumpWithI18n(tester, shell);

    final Finder btn = find.byKey(const Key('changePw.submit'));
    expect(tester.widget<ElevatedButton>(btn).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('changePw.input')), 'short');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(btn).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('changePw.input')),
      'verysecurepass',
    );
    await tester.pump();
    expect(tester.widget<ElevatedButton>(btn).onPressed, isNotNull);

    await tester.tap(btn);
    await tester.pumpAndSettle();
    expect(captured, 'verysecurepass');
  });
}
