import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../intros/providers/intros_providers.dart';
import 'widgets/connect_bottom_nav_bar.dart';

/// `StatefulShellRoute.indexedStack` body — host scaffold for the 5 main
/// tabs (Home / Inbox / Network / Opportunities / Chats). Each tab's stack
/// preserves its scroll position + history because the branches are kept
/// alive in the IndexedStack.
///
/// Bottom-nav badge counts hang off Riverpod providers per tab so each
/// surface owns its own unread shape:
/// - Inbox tab (index 1): `unreadIntrosCountProvider`
/// - Chats tab (index 4): wired in Phase 7 to `unreadCountsProvider`.
class TabShell extends ConsumerWidget {
  const TabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int introBadge =
        ref.watch(unreadIntrosCountProvider).asData?.value ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ConnectBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        badgeCounts: <int, int>{
          if (introBadge > 0) 1: introBadge,
        },
        onTap: (i) => navigationShell.goBranch(
          i,
          // Tapping the active tab pops back to its root.
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
