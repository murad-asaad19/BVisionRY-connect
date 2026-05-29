import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/profile.dart';

/// Stale-goal nudge — two-tier visual model:
///
/// * **Soft** (≥28d, <56d): a muted inline reminder with a single "Update"
///   text-link affordance. Low-friction, dismissible.
/// * **Hard** (≥56d): the full warning [AppBanner] with "Yes, still
///   accurate" + "Update" buttons. This is the original spec card.
///
/// Renders [SizedBox.shrink] when the goal is fresh. The two thresholds
/// live on the [Profile] model as [Profile.isGoalStale] /
/// [Profile.isGoalVeryStale].
class GoalRefreshCard extends StatelessWidget {
  const GoalRefreshCard({
    super.key,
    required this.profile,
    required this.onUpdate,
    this.onDismiss,
  });

  final Profile profile;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  /// Whole weeks elapsed since the goal was last updated, floored at 1 so the
  /// copy never reads "0 weeks ago". Falls back to the soft threshold (4) when
  /// [Profile.goalUpdatedAt] is unexpectedly null on a stale profile.
  int _weeksSinceUpdate() {
    final DateTime? updated = profile.goalUpdatedAt;
    if (updated == null) return 4;
    final int days = DateTime.now().toUtc().difference(updated).inDays;
    return (days ~/ 7).clamp(1, 520);
  }

  @override
  Widget build(BuildContext context) {
    if (!profile.isGoalStale) {
      return const SizedBox.shrink(
        key: ValueKey<String>('goal-refresh-card-fresh'),
      );
    }
    if (!profile.isGoalVeryStale) {
      return _SoftNudge(onUpdate: onUpdate, onDismiss: onDismiss);
    }
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final int weeks = _weeksSinceUpdate();
    final String goal = (profile.goalText ?? '').trim();
    return AppBanner(
      key: const ValueKey<String>('goal-refresh-card'),
      intent: AppIntent.warning,
      title: context.t('profile.goalRefresh.titleStale'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Body quotes the user's current goal + the elapsed time so they
          // know exactly what they're confirming (mockup I1 line 2296).
          Text(
            context.t(
              'profile.goalRefresh.bodyStale',
              vars: <String, Object>{'weeks': weeks},
            ),
          ),
          if (goal.isNotEmpty) ...<Widget>[
            Gap(spacing.xs),
            Text(
              '"$goal"',
              style: typo.bodyMd.copyWith(
                color: colors.navy,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Gap(spacing.sm),
          Row(
            children: <Widget>[
              AppButton(
                key: const Key('goalRefresh.stillAccurate'),
                label: context.t('profile.goalRefresh.stillAccurate'),
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                fullWidth: false,
                onPressed: onDismiss,
              ),
              Gap(spacing.sm),
              AppButton(
                key: const Key('goalRefresh.update'),
                label: context.t('profile.goalRefresh.update'),
                variant: AppButtonVariant.gold,
                size: AppButtonSize.small,
                fullWidth: false,
                onPressed: onUpdate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoftNudge extends StatelessWidget {
  const _SoftNudge({required this.onUpdate, this.onDismiss});

  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      key: const ValueKey<String>('goal-refresh-card-soft'),
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.sm,
        spacing.md,
        spacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.t('profile.goalRefresh.softNudge'),
              style: typo.bodySm.copyWith(color: colors.muted),
            ),
          ),
          Gap(spacing.sm),
          TextButton(
            key: const Key('goalRefresh.softUpdate'),
            onPressed: onUpdate,
            child: Text(context.t('profile.goalRefresh.update')),
          ),
          if (onDismiss != null)
            AppIconButton(
              key: const Key('goalRefresh.softDismiss'),
              icon: Icons.close,
              size: AppIconButtonSize.sm,
              label: context.t('profile.goalRefresh.stillAccurate'),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
