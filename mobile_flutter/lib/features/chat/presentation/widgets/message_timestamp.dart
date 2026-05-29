import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Centered timestamp separator rendered above the first message of each
/// ~5-min cluster. Format:
/// - same day  → `3:14 PM`
/// - this week → `Mon 3:14 PM`
/// - older     → `May 27, 3:14 PM`
class MessageTimestamp extends StatelessWidget {
  const MessageTimestamp({super.key, required this.at});

  final DateTime at;

  static String format(DateTime at, {DateTime? now}) {
    final local = at.toLocal();
    final ref = (now ?? DateTime.now()).toLocal();
    final sameDay = local.year == ref.year &&
        local.month == ref.month &&
        local.day == ref.day;
    if (sameDay) {
      return DateFormat.jm().format(local);
    }
    final daysAgo = ref.difference(local).inDays;
    if (daysAgo < 7 && daysAgo >= 0) {
      // Locale-aware "Mon 3:14 PM" — skeletons (E + jm) follow the locale's
      // weekday abbreviation and 12h/24h convention; no hardcoded pattern.
      return DateFormat.E().add_jm().format(local);
    }
    // Locale-aware "May 27, 3:14 PM" → month-day + time skeletons.
    return DateFormat.MMMd().add_jm().format(local);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          format(at),
          style: typo.bodyXs.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
