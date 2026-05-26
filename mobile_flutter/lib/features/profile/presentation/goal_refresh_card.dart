import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/profile.dart';

/// Stale-goal banner — surfaces when [Profile.isGoalStale] is true (>28 days
/// / 4 weeks since the user last changed their goal_text, per the gallery
/// section I1 spec). The Phase-13 decay model (50% at week 12) still owns
/// the *server*-side staleness pipeline; this is the client-side first nudge.
///
/// Renders nothing when the profile's goal is fresh. Two inline actions:
///   - "Yes, still accurate" (outline) — calls [onDismiss] to hide the
///     banner. Replaces the prior tiny X icon to match the gallery affordance
///     (gallery section I1, lines 2295–2298).
///   - "Update" (gold solid) — calls [onUpdate], typically routes to
///     `/profile/edit`.
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
