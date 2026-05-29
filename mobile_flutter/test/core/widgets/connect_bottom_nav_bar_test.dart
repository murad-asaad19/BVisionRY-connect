// ConnectBottomNavBar test — 5 Lucide tabs (Home/Network/Inbox/
// Opportunities/Profile). The chats list folds into the Inbox tab, so the
// inbox badge = unread intros + unread chats and there is no standalone
// Chats tab. Uses the i18n primed loader so the labels resolve.
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
        ),
        loader: loader,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
    expect(find.byIcon(LucideIcons.users), findsOneWidget);
    expect(find.byIcon(LucideIcons.inbox), findsOneWidget);
    expect(find.byIcon(LucideIcons.briefcase), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleUser), findsOneWidget);
    // No standalone Chats tab — chats fold into the Inbox.
    expect(find.byIcon(LucideIcons.messageSquare), findsNothing);
  });

  testWidgets('Inbox badge renders the combined unread count',
      (WidgetTester tester) async {
    final LocaleLoader loader = await primedLocaleLoader();
    await tester.pumpWidget(
      await host(
        ConnectBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
          inboxUnread: 16,
          opportunitiesUnread: 3,
        ),
        loader: loader,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('16'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
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
          opportunitiesUnread: 100,
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
        ),
        loader: loader,
      ),
    );
    await tester.pumpAndSettle();
    // Network is the second tab (index 1) in the 5-tab nav.
    await tester.tap(find.byIcon(LucideIcons.users));
    await tester.pumpAndSettle();
    expect(lastTapped, 1);
  });
}
