import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pill-shaped unread badge used on the bottom-nav inbox + chats tabs.
///
/// Visual (spec §7.2):
///   * Gold background (`#FFC107`), navy text (`#0F3460`), bold 10pt.
///   * Minimum 16×16 hit area so single-digit counts stay legible.
///   * Caps the visible label at `99+` so 3-digit counts never overflow
///     and look broken on small phones.
///   * Hidden entirely when `count <= 0` so the icon column stays aligned.
class TabBadge extends StatelessWidget {
  const TabBadge({super.key, required this.count});

  /// Number of unread items. `<= 0` collapses the widget; `> 99` renders
  /// as `99+`.
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final String label = count > 99 ? '99+' : '$count';
    return Container(
      key: const Key('tab_badge.container'),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: colors.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: colors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.2,
        ),
      ),
    );
  }
}
