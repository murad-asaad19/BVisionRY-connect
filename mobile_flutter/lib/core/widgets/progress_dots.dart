import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Onboarding / wizard progress indicator.
///
/// Renders [total] round dots (8px circles) in three states matching the
/// gallery's `.step-dots`: past dots (i < current) paint navy, the current
/// dot (i == current) paints gold, pending dots (i > current) use the
/// muted border colour. See `connect-full-app-gallery.html:1229`.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.total,
    required this.current,
  })  : assert(total > 0, 'total must be > 0'),
        assert(current >= 0, 'current must be >= 0');

  /// Total number of dots.
  final int total;

  /// 0-indexed position of the active dot. Values >= [total] paint every
  /// dot navy (all-complete state).
  final int current;

  /// Visual diameter of each dot.
  static const double _dotSize = 8;

  /// Horizontal spacing between adjacent dots.
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      label: 'Progress',
      value: '${(current + 1).clamp(1, total)} of $total',
      child: Row(
        key: const ValueKey('progress-dots-frame'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final Color color;
          if (i < current) {
            color = c.navy;
          } else if (i == current) {
            color = c.gold;
          } else {
            color = c.border;
          }
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : _gap),
            child: Container(
              key: ValueKey('progress-dot-$i'),
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
