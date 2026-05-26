import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
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
    return AppBanner(
      key: const ValueKey<String>('goal-refresh-card'),
      intent: AppIntent.warning,
      title: context.t('profile.goalRefresh.titleStale'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(context.t('profile.goalRefresh.bodyStale')),
          const SizedBox(height: 8),
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
              const SizedBox(width: 8),
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
    final c = Theme.of(context).extension<AppColors>()!;
    final t = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      key: const ValueKey<String>('goal-refresh-card-soft'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.t('profile.goalRefresh.softNudge'),
              style: t.bodySm.copyWith(color: c.muted),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: const Key('goalRefresh.softUpdate'),
            onPressed: onUpdate,
            child: Text(context.t('profile.goalRefresh.update')),
          ),
          if (onDismiss != null)
            IconButton(
              key: const Key('goalRefresh.softDismiss'),
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDismiss,
              tooltip: context.t('profile.goalRefresh.stillAccurate'),
            ),
        ],
      ),
    );
  }
}
