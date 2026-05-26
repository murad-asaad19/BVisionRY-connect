import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
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
            child: _MutualsStack(
              count: signals.mutualConnectionCount,
              topUserIds: signals.mutualTopUserIds,
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

/// Overlapping mini-avatar stack (gallery section D1 lines 1654-1659).
///
/// Renders up to 3 24px avatars at -8px overlap, followed by the count text
/// (e.g. "3 people you both know" / "+N more"). When [topUserIds] doesn't
/// carry photo URLs (the current RPC shape only returns ids) we fall back
/// to initials placeholders driven by [Avatar]'s default appearance.
class _MutualsStack extends StatelessWidget {
  const _MutualsStack({required this.count, required this.topUserIds});

  final int count;
  final List<String> topUserIds;

  static const int _maxAvatars = 3;
  static const double _avatarSize = 24;
  static const double _overlap = -8;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final int shown = topUserIds.length.clamp(0, _maxAvatars);
    // If the signals payload only has a count (no ids), still render N
    // placeholders so the visual treatment is consistent.
    final int placeholders = shown == 0 ? count.clamp(0, _maxAvatars) : shown;
    final int leftover = count - placeholders;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (placeholders > 0)
          SizedBox(
            height: _avatarSize,
            width: _avatarSize + (placeholders - 1) * (_avatarSize + _overlap),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                for (int i = 0; i < placeholders; i++)
                  Positioned(
                    left: i * (_avatarSize + _overlap),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: Avatar(
                        name: i < topUserIds.length ? topUserIds[i] : '',
                        size: _avatarSize,
                        tone: AvatarTone.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (placeholders > 0) const SizedBox(width: 8),
        Text(
          leftover > 0
              ? context.t(
                  'profile.signals.mutualPlus',
                  vars: <String, Object>{'count': leftover},
                )
              : context.t(
                  'profile.signals.mutual',
                  vars: <String, Object>{'count': count},
                ),
          style: typo.bodySm.copyWith(color: colors.body),
        ),
      ],
    );
  }
}
