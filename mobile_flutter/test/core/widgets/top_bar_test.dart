import 'package:connect_mobile/core/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('TopBar renders title and subtitle', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: TopBar(title: 'Home', subtitle: 'Connect with operators'),
        ),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Connect with operators'), findsOneWidget);
  });

  testWidgets('TopBar back button calls onBack', (tester) async {
    var popped = false;
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          body: TopBar(
            title: 'Detail',
            back: true,
            onBack: () => popped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Back'));
    expect(popped, isTrue);
  });

  testWidgets('TopBar renders actions', (tester) async {
    var tapped = false;
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          body: TopBar(
            title: 'Inbox',
            actions: [
              TopBarAction(
                icon: Icons.search,
                onPressed: () => tapped = true,
                label: 'Search',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Search'));
    expect(tapped, isTrue);
  });
}
