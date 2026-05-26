import 'package:connect_mobile/features/settings/presentation/widgets/delete_account_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('DeleteAccountSheet disables Delete until DELETE typed exactly',
      (WidgetTester tester) async {
    bool confirmed = false;
    final Widget shell = await wrapWithTheme(
      child: Scaffold(
        body: DeleteAccountSheet(
          onConfirm: () async => confirmed = true,
        ),
      ),
    );
    await pumpWithI18n(tester, shell);

    final Finder confirmFinder = find.byKey(const Key('deleteSheet.confirmBtn'));
    ElevatedButton btn = tester.widget<ElevatedButton>(confirmFinder);
    expect(btn.onPressed, isNull); // disabled by default

    await tester.enterText(
      find.byKey(const Key('deleteSheet.confirmInput')),
      'delete',
    );
    await tester.pump();
    btn = tester.widget<ElevatedButton>(confirmFinder);
    expect(btn.onPressed, isNull, reason: 'lowercase should not enable');

    await tester.enterText(
      find.byKey(const Key('deleteSheet.confirmInput')),
      'DELETE',
    );
    await tester.pump();
    btn = tester.widget<ElevatedButton>(confirmFinder);
    expect(btn.onPressed, isNotNull, reason: 'exact match should enable');

    await tester.tap(confirmFinder);
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
