import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Eyebrow rendered above the daily-matches list.
///
/// Format: navy uppercase `TODAY · 3 PICKS` with a tiny muted date line
/// underneath ("Mon, Apr 28") and a gold star to the right. The
/// present-tense wording reads more immediate than the gallery's
/// newspaper-style "3 PICKS FOR YOU · MON, APR 28".
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
    final formatted = DateFormat('EEE, MMM d').format(date);
    final picksWord = context.t(
      'home.picksHeader',
      vars: <String, Object>{'count': count},
    ).toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'TODAY · $picksWord',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.displayXs.copyWith(
                    color: c.navy,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySm.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          Text('★', style: t.displayXs.copyWith(color: c.gold)),
        ],
      ),
    );
  }
}
