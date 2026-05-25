import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Uppercase 11px section eyebrow rendered above the daily-matches list.
///
/// Format: `"<COUNT> PICKS FOR YOU · <FORMATTED DATE>"` with a trailing
/// star glyph in gold (the gallery's ph-section affordance).
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
    final formatted = DateFormat(
      'EEE, MMM d',
      Localizations.localeOf(context).languageCode,
    ).format(date).toUpperCase();
    final pickWord = context
        .t(
          'home.picksHeader',
          vars: <String, Object>{'count': count},
        )
        .toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              '$pickWord · $formatted',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.displayXs.copyWith(
                color: c.muted,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Text('★', style: t.displayXs.copyWith(color: c.gold)),
        ],
      ),
    );
  }
}
