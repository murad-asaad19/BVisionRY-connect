import 'package:flutter/material.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';

/// The 5-tab branded BottomNavigationBar used by [TabShell].
///
/// Visual: white background, navy selected, muted unselected. Icon glyphs
/// mirror the gallery (home/inbox/network/work/chat). Badges (for unread
/// counts) are deferred to Phases 6/7/10.
class ConnectBottomNavBar extends StatelessWidget {
  const ConnectBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: c.white,
      selectedItemColor: c.navy,
      unselectedItemColor: c.muted,
      currentIndex: currentIndex,
      onTap: onTap,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: context.t('common.tabs.home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inbox_outlined),
          activeIcon: const Icon(Icons.inbox),
          label: context.t('common.tabs.inbox'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_outline),
          activeIcon: const Icon(Icons.people),
          label: context.t('common.tabs.network'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.work_outline),
          activeIcon: const Icon(Icons.work),
          label: context.t('common.tabs.opportunities'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat_bubble_outline),
          activeIcon: const Icon(Icons.chat_bubble),
          label: context.t('common.tabs.chats'),
        ),
      ],
    );
  }
}
