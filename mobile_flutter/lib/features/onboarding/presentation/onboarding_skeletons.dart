import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// Shape-matching loading placeholder for the simpler onboarding steps
/// (title + subtitle + a stack of labelled inputs / a chip row). Replaces the
/// bare centered spinner that used to flash while the persisted draft
/// hydrates, so the layout doesn't jump when the real content lands.
///
/// [fields] controls how many labelled-input rows to draw; [chipRow] appends
/// a row of pill skeletons (used by the Roles step's chip selector).
class OnboardingFormSkeleton extends StatelessWidget {
  const OnboardingFormSkeleton({
    super.key,
    this.fields = 2,
    this.chipRow = false,
  });

  final int fields;
  final bool chipRow;

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Skeleton(width: 200, height: 24),
        Gap(spacing.sm),
        const Skeleton(width: 240, height: 14),
        Gap(spacing.card),
        for (int i = 0; i < fields; i++) ...<Widget>[
          const Skeleton(width: 80, height: 10),
          Gap(spacing.xs),
          const Skeleton(width: double.infinity, height: 44, rounded: 10),
          Gap(spacing.card),
        ],
        if (chipRow)
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Skeleton(width: 90, height: 32, rounded: 999),
              Skeleton(width: 80, height: 32, rounded: 999),
              Skeleton(width: 100, height: 32, rounded: 999),
              Skeleton(width: 90, height: 32, rounded: 999),
            ],
          ),
      ],
    );
  }
}
