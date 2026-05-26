// Phase 13 ConnectBottomNavBar test — 5 Lucide tabs + live badges from
// inbox + chats. Uses the i18n primed loader so the labels resolve.
import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/connect_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/pump.dart';

Future<Widget> host(
  Widget child, {
  required LocaleLoader loader,
}) async {
  return ProviderScope(
    overrides: <Override>[
      localeLoaderProvider.overrideWithValue(loader),
    ],
    child: MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(bottomNavigationBar: child),
    ),
  );
}

void main() {
  testWidgets('ConnectBottomNavBar renders 5 Lucide tab icons',
      (WidgetTester tester) async {
    final LocaleLoader loader = await primedLocaleLoader();
    await tester.pumpWidget(
      await host(
        ConnectBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
          inboxUnread: 0,
          chatsUnread: 0,
        ),
        loader: loader,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
    expect(find.byIcon(LucideIcons.inbox), findsOneWidget);
    expect(find.byIcon(LucideIcons.users), findsOneWidget);
    expect(find.byIcon(LucideIcons.briefcase), findsOneWidget);
    expect(find.byIcon(LucideIcons.messageSquare), findsOneWidget);
  });

  testWidgets('Badges render on inbox + chats when unread > 0',
      (WidgetTester tester) async {
    final LocaleLoader loader = await primedLocaleLoader();
    await tester.pumpWidget(
      await host(
        ConnectBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
          inboxUnread: 4,
          chatsUnread: 12,
        ),
        loader: loader,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('Badge labels cap at 99+ when count > 99',
      (WidgetTester tester) async {
    final LocaleLoader loader = await primedLocaleLoader();
    await tester.pumpWidget(
      await host(
        ConnectBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
          inboxUnread: 250,
          chatsUnread: 100,
        ),
        loader: loader,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsNWidgets(2));
  });

  testWidgets('onTap fires with tapped index', (WidgetTester tester) async {
    final LocaleLoader loader = await primedLocaleLoader();
    int lastTapped = -1;
    await tester.pumpWidget(
      await host(
        ConnectBottomNavBar(
          currentIndex: 0,
          onTap: (int i) => lastTapped = i,
          inboxUnread: 0,
          chatsUnread: 0,
        ),
        loader: loader,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.users));
    await tester.pumpAndSettle();
    expect(lastTapped, 2);
  });
}
