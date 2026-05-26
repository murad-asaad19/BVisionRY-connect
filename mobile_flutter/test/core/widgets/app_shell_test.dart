// Phase 13 AppShell test. Verifies the shell reads the unread counts from
// the Phase 6 + 7 providers and forwards them into [ConnectBottomNavBar].
import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_shell.dart';
import 'package:connect_mobile/core/widgets/connect_bottom_nav_bar.dart';
import 'package:connect_mobile/features/chat/providers/unread_counts_provider.dart';
import 'package:connect_mobile/features/intros/providers/intros_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump.dart';

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (BuildContext _, GoRouterState __, StatefulNavigationShell shell) =>
                AppShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          for (final String path in const <String>[
            '/home',
            '/inbox',
            '/network',
            '/opportunities',
            '/chats',
          ])
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: path,
                  builder: (_, __) => Scaffold(body: Center(child: Text(path))),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('AppShell forwards unread badges into ConnectBottomNavBar',
      (WidgetTester tester) async {
    final LocaleLoader loader = await primedLocaleLoader();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          localeLoaderProvider.overrideWithValue(loader),
          unreadIntrosCountProvider
              .overrideWith((Ref<AsyncValue<int>> _) async => 3),
          unreadCountsProvider.overrideWith(
              (Ref<AsyncValue<Map<String, int>>> _) async =>
                  <String, int>{'c1': 4, 'c2': 5},),
        ],
        child: MaterialApp.router(
          theme: buildAppTheme(Brightness.light),
          routerConfig: _testRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ConnectBottomNavBar bar = tester.widget<ConnectBottomNavBar>(
      find.byType(ConnectBottomNavBar),
    );
    expect(bar.inboxUnread, 3);
    expect(bar.chatsUnread, 9);
  });
}
