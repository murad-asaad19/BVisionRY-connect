import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Onboarding / wizard progress indicator.
///
/// Renders [total] horizontal bars; bars before [current] are painted navy,
/// the bar at [current] is gold, and remaining bars use the muted [border]
/// colour. This matches the audit P3-4 update of the gallery treatment.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.total,
    required this.current,
  })  : assert(total > 0, 'total must be > 0'),
        assert(current >= 0, 'current must be >= 0');

  /// Total number of segments.
  final int total;

  /// 0-indexed position of the active segment. Values >= [total] paint
  /// every bar navy (all-complete state).
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      label: 'Progress',
      value: '${(current + 1).clamp(1, total)} of $total',
      child: Row(
        key: const ValueKey('progress-dots-frame'),
        children: List.generate(total, (i) {
          final Color bg;
          if (i < current) {
            bg = c.navy;
          } else if (i == current) {
            bg = c.gold;
          } else {
            bg = c.border;
          }
          return Expanded(
            child: Container(
              key: ValueKey('progress-dot-$i'),
              margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
