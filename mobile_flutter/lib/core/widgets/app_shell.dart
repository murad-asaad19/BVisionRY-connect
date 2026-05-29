import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/providers/unread_counts_provider.dart';
import '../../features/intros/providers/intros_providers.dart';
import '../../features/opportunities/providers/interest_badge_provider.dart';
import 'connect_bottom_nav_bar.dart';

/// Host scaffold for the 5-tab `StatefulShellRoute.indexedStack`
/// (Home / Network / Inbox / Opportunities / Profile).
///
/// Each tab branch is kept alive inside the IndexedStack so navigation
/// preserves per-tab scroll position and nav-stack history. Bottom-nav
/// badge counts source from feature providers and attach to their tab by
/// identity (the nav bar maps them, not this shell):
///
///   * Inbox tab: `unreadIntrosCountProvider` (Phase 6) PLUS the sum of
///     `unreadCountsProvider` values (Phase 7) — the chats list is now an
///     Inbox segment, so its unread conversations fold into the Inbox badge.
///   * Opportunities tab: `opportunitiesInterestBadgeProvider`.
///
/// Tapping the active tab re-issues `goBranch(...,
/// initialLocation: true)` to pop back to that branch's root, matching
/// the platform-native expectation.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  /// Shell host provided by `StatefulShellRoute.indexedStack`.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int introBadge =
        ref.watch(unreadIntrosCountProvider).asData?.value ?? 0;
    final Map<String, int>? unread =
        ref.watch(unreadCountsProvider).asData?.value;
    final int chatsBadge = unread == null
        ? 0
        : unread.values.fold<int>(0, (int a, int b) => a + b);
    final int opportunitiesBadge =
        ref.watch(opportunitiesInterestBadgeProvider).asData?.value ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ConnectBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        // Chats folded into the Inbox tab → its badge carries both unread
        // intro requests and unread conversation messages.
        inboxUnread: introBadge + chatsBadge,
        opportunitiesUnread: opportunitiesBadge,
        onTap: (int i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
