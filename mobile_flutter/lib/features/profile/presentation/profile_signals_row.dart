import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/profile_signals.dart';

/// Mutual-connections + rating signals row.
///
/// Three render states (per spec §17.6):
///   1. **Hidden** — when both [signals.mutualConnectionCount] is 0 and
///      [signals.showRating] is false the widget collapses to a 0-height box.
///   2. **Count only** — mutuals row visible, rating hidden (because
///      `total_meeting_reviews < 3` or `avg_meeting_rating == null`).
///   3. **Both visible** — mutuals row + rating row (chip with star icon).
///
/// The mutual avatar stack (top 5 ids overlapping) is a Phase 15 polish task
/// per the chunk-B brief; here we render the count + "in common" label.
class ProfileSignalsRow extends StatelessWidget {
  const ProfileSignalsRow({super.key, required this.signals});

  final ProfileSignals signals;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;

    final bool showMutuals = signals.mutualConnectionCount > 0;
    final bool showRating = signals.showRating;
    if (!showMutuals && !showRating) {
      return const SizedBox.shrink(
        key: ValueKey<String>('profile-signals-empty'),
      );
    }

    return Row(
      key: const ValueKey<String>('profile-signals-row'),
      children: <Widget>[
        if (showMutuals)
          Padding(
            key: const Key('profileSignals.mutuals'),
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              context.t(
                'profile.signals.mutual',
                vars: <String, Object>{'count': signals.mutualConnectionCount},
              ),
              style: typo.bodyMd.copyWith(color: colors.body),
            ),
          ),
        if (showRating)
          Row(
            key: const Key('profileSignals.rating'),
            children: <Widget>[
              Icon(Icons.star, size: 14, color: colors.gold),
              const SizedBox(width: 4),
              Text(
                signals.avgMeetingRating!.toStringAsFixed(1),
                style: typo.bodyMd.copyWith(
                  color: colors.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.t(
                  'profile.signals.reviews',
                  vars: <String, Object>{
                    'count': signals.totalMeetingReviews,
                  },
                ),
                style: typo.bodySm.copyWith(color: colors.muted),
              ),
            ],
          ),
      ],
    );
  }
}
