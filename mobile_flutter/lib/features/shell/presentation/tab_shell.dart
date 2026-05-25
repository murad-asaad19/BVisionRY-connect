import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/connect_bottom_nav_bar.dart';

/// `StatefulShellRoute.indexedStack` body — host scaffold for the 5 main
/// tabs (Home / Inbox / Network / Opportunities / Chats). Each tab's stack
/// preserves its scroll position + history because the branches are kept
/// alive in the IndexedStack.
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ConnectBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          // Tapping the active tab pops back to its root.
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
