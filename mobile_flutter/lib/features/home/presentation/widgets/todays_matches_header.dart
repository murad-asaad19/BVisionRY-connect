import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Eyebrow rendered above the daily-matches list.
///
/// Newspaper-style single line matching gallery C1 (line 1419):
/// `3 PICKS FOR YOU · MON, APR 28` in navy uppercase Dosis with a trailing
/// gold ★. The date is locale-formatted (abbreviated weekday + month + day)
/// and folded into the same line rather than split onto a muted sub-line.
class TodaysMatchesHeader extends StatelessWidget {
  const TodaysMatchesHeader({
    super.key,
    required this.count,
    required this.date,
  });

  final int count;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final t = Theme.of(context).extension<AppTypography>()!;
    // Locale-aware abbreviated weekday + month + day (e.g. "Mon, Apr 28" in
    // en, localized month/weekday names + ordering elsewhere) — no hardcoded
    // pattern so the format follows the active locale.
    final formatted = DateFormat.MMMEd().format(date);
    final picks = context.t(
      'home.picksForYou',
      vars: <String, Object>{'count': count},
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              '$picks · $formatted'.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.displayXs.copyWith(
                color: c.navy,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('★', style: t.displayXs.copyWith(color: c.gold)),
        ],
      ),
    );
  }
}
