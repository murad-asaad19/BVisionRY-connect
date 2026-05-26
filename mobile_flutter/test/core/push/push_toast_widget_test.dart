import 'package:connect_mobile/core/push/push_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('PushToast renders title and body and routes on tap',
      (WidgetTester tester) async {
    bool tapped = false;
    final Widget tree = await wrapWithTheme(
      child: Scaffold(
        body: PushToast(
          title: 'Acme wants to connect',
          body: 'Open to read the warm intro',
          onTap: () => tapped = true,
          onDismiss: () {},
        ),
      ),
    );
    await pumpWithI18n(tester, tree);

    expect(find.text('Acme wants to connect'), findsOneWidget);
    expect(find.text('Open to read the warm intro'), findsOneWidget);

    await tester.tap(find.byType(PushToast));
    expect(tapped, isTrue);
  });

  testWidgets('PushToast tap area has minimum 44dp height',
      (WidgetTester tester) async {
    final Widget tree = await wrapWithTheme(
      child: Scaffold(
        body: PushToast(
          title: 't',
          body: 'b',
          onTap: () {},
          onDismiss: () {},
        ),
      ),
    );
    await pumpWithI18n(tester, tree);
    final Size box = tester.getSize(find.byType(PushToast));
    expect(box.height, greaterThanOrEqualTo(44));
  });

  testWidgets('PushToast renders dismiss button with tooltip',
      (WidgetTester tester) async {
    final Widget tree = await wrapWithTheme(
      child: Scaffold(
        body: PushToast(
          title: 't',
          body: 'b',
          onTap: () {},
          onDismiss: () {},
        ),
      ),
    );
    await pumpWithI18n(tester, tree);
    expect(find.byTooltip('Dismiss notification'), findsOneWidget);
  });

  testWidgets('PushToast dismiss button invokes onDismiss callback',
      (WidgetTester tester) async {
    bool dismissed = false;
    final Widget tree = await wrapWithTheme(
      child: Scaffold(
        body: PushToast(
          title: 't',
          body: 'b',
          onTap: () {},
          onDismiss: () => dismissed = true,
        ),
      ),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byTooltip('Dismiss notification'));
    expect(dismissed, isTrue);
  });
}
