import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/profile.dart';

/// Stale-goal banner — surfaces when [Profile.isGoalStale] is true (>56 days
/// since the user last changed their goal_text, per spec §17.5).
///
/// Renders nothing when the profile's goal is fresh. Tap "Update" → call
/// [onUpdate] (typically routes to /profile/edit). Tap "Still accurate" →
/// call [onDismiss] (Phase-13 nags will persist the snooze; for now just
/// hide the banner in-session).
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
    return AppBanner(
      key: const ValueKey<String>('goal-refresh-card'),
      intent: AppIntent.warning,
      title: context.t('profile.goalRefresh.titleStale'),
      onClose: onDismiss,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(context.t('profile.goalRefresh.bodyStale')),
          const SizedBox(height: 8),
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
    );
  }
}
