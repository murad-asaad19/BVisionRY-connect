import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/settings/presentation/widgets/tab_badge.dart';
import '../i18n/i18n.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Finalized 5-tab bottom navigation bar — promoted from the Phase 5 stub
/// (which lived under `features/shell/presentation/widgets/`). Carries the
/// brand visual treatment + live unread badges sourced from
/// `unreadIntrosCountProvider` (Phase 6) and `unreadCountsProvider`
/// (Phase 7) via [AppShell].
///
/// Visual contract (spec §7.2):
///   * 5 destinations, Lucide icons: house / inbox / users / briefcase /
///     messageSquare.
///   * Active tab: navy icon + label. Inactive: muted slate.
///   * Tab bar height: 56 (content) + min(safe-area bottom inset, 24).
///   * Badges only on inbox (index 1) and chats (index 4). Cap visible
///     label at `99+`.
class ConnectBottomNavBar extends StatelessWidget {
  const ConnectBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.inboxUnread,
    required this.chatsUnread,
    this.opportunitiesUnread = 0,
  });

  /// Fixed content height — the safe-area inset is added on top, clamped
  /// to keep older notch devices from inflating the bar.
  static const double tabBarContentHeight = 56;

  /// Defensive cap on the bottom inset to keep the tab bar visually anchored
  /// even when the OS reports a generous safe-area (e.g. stale gesture
  /// indicator heights on Pixel devices).
  static const double maxBottomInset = 24;

  /// Tab index currently selected. Drives the active styling.
  final int currentIndex;

  /// Fired with the tapped tab index. Re-tapping the active index pops
  /// back to that branch's root — caller handles via `goBranch(...,
  /// initialLocation: ...)`.
  final ValueChanged<int> onTap;

  /// Unread intros count for the inbox tab badge (Phase 6).
  final int inboxUnread;

  /// Sum of unread message counts across all conversations for the chats
  /// tab badge (Phase 7).
  final int chatsUnread;

  /// Total interested-user count across the caller's open opportunities.
  /// Surfaces a badge so an author sees at-a-glance when somebody has
  /// expressed interest in their posts. UX gap #1 from validation walks.
  final int opportunitiesUnread;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final double bottomInset =
        math.min(MediaQuery.of(context).padding.bottom, maxBottomInset);

    final List<_TabDef> tabs = <_TabDef>[
      _TabDef(LucideIcons.house, context.t('common.tabs.home')),
      _TabDef(
        LucideIcons.inbox,
        context.t('common.tabs.inbox'),
        badge: inboxUnread,
      ),
      _TabDef(LucideIcons.users, context.t('common.tabs.network')),
      _TabDef(
        LucideIcons.briefcase,
        context.t('common.tabs.opportunities'),
        badge: opportunitiesUnread,
      ),
      _TabDef(
        LucideIcons.messageSquare,
        context.t('common.tabs.chats'),
        badge: chatsUnread,
      ),
    ];

    return Container(
      color: colors.white,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: tabBarContentHeight,
        child: Row(
          children: List<Widget>.generate(tabs.length, (int i) {
            final _TabDef t = tabs[i];
            final bool active = i == currentIndex;
            final Color color = active ? colors.navy : colors.muted;
            return Expanded(
              child: InkWell(
                key: Key('nav_tab_$i'),
                onTap: () => onTap(i),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(t.icon, size: 22, color: color),
                        const SizedBox(height: 2),
                        Text(
                          t.label,
                          style: typo.displayXs
                              .copyWith(color: color, fontSize: 10),
                        ),
                      ],
                    ),
                    if (t.badge != null && t.badge! > 0)
                      Positioned(
                        top: 6,
                        right: 24,
                        child: TabBadge(count: t.badge!),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.icon, this.label, {this.badge});
  final IconData icon;
  final String label;
  final int? badge;
}
