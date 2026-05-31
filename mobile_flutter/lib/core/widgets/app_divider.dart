import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Hairline separator.
///
/// Horizontal by default. When [label] is provided, splits the line into
/// two flex-1 segments with the centred uppercased text in between (used
/// in auth screens — "OR continue with"). Vertical mode renders a 1px
/// column that stretches to its parent's cross-axis.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.label,
    this.orientation = Axis.horizontal,
    this.indent = 0,
  });

  final String? label;
  final Axis orientation;

  /// Leading inset (logical pixels) for the horizontal no-label line, so a
  /// divider can start past a leading avatar/icon. Default 0 keeps the line
  /// edge-to-edge.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;

    if (orientation == Axis.vertical) {
      return Container(
        key: const ValueKey('divider-line'),
        constraints: const BoxConstraints.tightFor(width: 1),
        color: colors.border,
      );
    }

    if (label != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              key: const ValueKey('divider-line'),
              constraints: const BoxConstraints.tightFor(height: 1),
              color: colors.border,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!.toUpperCase(),
              style: typo.bodySm.copyWith(
                color: colors.muted,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints.tightFor(height: 1),
              color: colors.border,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: Container(
        key: const ValueKey('divider-line'),
        constraints: const BoxConstraints.tightFor(height: 1),
        color: colors.border,
      ),
    );
  }
}
