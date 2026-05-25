import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';

/// Loading placeholder for the home daily-matches list. Renders 3 stacked
/// 96dp rectangles (matching the shape of a featured [MatchCard]) so the
/// transition from loading → loaded doesn't shift the viewport.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Skeleton(height: 96, rounded: 14),
    );
  }
}
