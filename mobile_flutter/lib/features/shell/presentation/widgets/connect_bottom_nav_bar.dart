import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';

/// The 5-tab branded BottomNavigationBar used by [TabShell].
///
/// Visual: white background, navy selected, muted unselected. Icon glyphs
/// mirror the gallery (home / inbox / network / work / chat). Badge counts
/// are wired through [badgeCounts] keyed by tab index — Phase 6 wires the
/// Inbox tab from `unreadIntrosCountProvider`, Phase 7 will wire the Chats
/// tab from the chat unread count provider.
class ConnectBottomNavBar extends StatelessWidget {
  const ConnectBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts = const <int, int>{},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Optional per-tab unread / pending counts keyed by tab index. A count
  /// of `0` (or a missing key) suppresses the dot; any positive value
  /// renders a navy dot with white text (capped at "99+" to keep the
  /// chip readable).
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    Widget badged(IconData icon, int index) {
      final int count = badgeCounts[index] ?? 0;
      final iconWidget = Icon(icon);
      if (count <= 0) return iconWidget;
      return Badge(
        key: ValueKey<String>('nav-tab-badge-$index'),
        label: Text(_formatCount(count)),
        backgroundColor: c.navy,
        textColor: c.white,
        child: iconWidget,
      );
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: c.white,
      selectedItemColor: c.navy,
      unselectedItemColor: c.muted,
      currentIndex: currentIndex,
      onTap: onTap,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: badged(Icons.home_outlined, 0),
          activeIcon: badged(Icons.home, 0),
          label: context.t('common.tabs.home'),
        ),
        BottomNavigationBarItem(
          icon: badged(Icons.inbox_outlined, 1),
          activeIcon: badged(Icons.inbox, 1),
          label: context.t('common.tabs.inbox'),
        ),
        BottomNavigationBarItem(
          icon: badged(Icons.people_outline, 2),
          activeIcon: badged(Icons.people, 2),
          label: context.t('common.tabs.network'),
        ),
        BottomNavigationBarItem(
          icon: badged(Icons.work_outline, 3),
          activeIcon: badged(Icons.work, 3),
          label: context.t('common.tabs.opportunities'),
        ),
        BottomNavigationBarItem(
          icon: badged(Icons.chat_bubble_outline, 4),
          activeIcon: badged(Icons.chat_bubble, 4),
          label: context.t('common.tabs.chats'),
        ),
      ],
    );
  }

  /// Caps the visible badge label at "99+" — anything higher overflows the
  /// material `Badge` chip and looks broken on small screens.
  String _formatCount(int n) => n > 99 ? '99+' : '$n';
}
