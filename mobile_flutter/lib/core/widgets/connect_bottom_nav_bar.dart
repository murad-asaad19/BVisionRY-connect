import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/settings/presentation/widgets/tab_badge.dart';
import '../i18n/i18n.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Bottom navigation bar — 5 destinations. Carries the brand visual treatment
/// + live unread badges sourced from `unreadIntrosCountProvider` (Phase 6) and
/// `unreadCountsProvider` (Phase 7) via [AppShell].
///
/// Visual contract:
///   * 5 destinations, Lucide icons: house / users / inbox / briefcase /
///     circleUser → Home / Network / Inbox / Opportunities / Profile.
///   * The chats list is a segment of the Inbox (no standalone tab), so the
///     Inbox badge folds in unread conversations on top of unread intros.
///   * Active tab: navy icon + label. Inactive: muted slate.
///   * Tab bar height: 56 (content) + min(safe-area bottom inset, 24).
///   * Badges attach to the Inbox and Opportunities tabs by identity (not
///     index), capped at `99+`. Labels [FittedBox]-shrink to fit the per-tab
///     width so a long word ("Opportunities") never clips.
class ConnectBottomNavBar extends StatelessWidget {
  const ConnectBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.inboxUnread,
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

  /// Combined unread count for the Inbox tab badge: unread intro requests
  /// (Phase 6) plus unread conversation messages (Phase 7), since the chats
  /// list now lives inside the Inbox.
  final int inboxUnread;

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
      _TabDef(LucideIcons.users, context.t('common.tabs.network')),
      _TabDef(
        LucideIcons.inbox,
        context.t('common.tabs.inbox'),
        badge: inboxUnread,
      ),
      _TabDef(
        LucideIcons.briefcase,
        context.t('common.tabs.opportunities'),
        badge: opportunitiesUnread,
      ),
      _TabDef(LucideIcons.circleUser, context.t('common.tabs.profile')),
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
              child: Semantics(
                selected: active,
                button: true,
                label: t.label,
                child: MergeSemantics(
                  child: InkWell(
                    key: Key('nav_tab_$i'),
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            Icon(t.icon, size: 22, color: color),
                            if (t.badge != null && t.badge! > 0)
                              Positioned(
                                top: -6,
                                right: -10,
                                child: TabBadge(count: t.badge!),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Shrink-to-fit keeps a long word ("Opportunities")
                        // fully visible at the tighter 6-tab width instead of
                        // clipping or forcing an ellipsis.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t.label,
                              maxLines: 1,
                              style: typo.displayXs
                                  .copyWith(color: color, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
