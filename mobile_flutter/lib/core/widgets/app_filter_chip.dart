import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

/// Rounded-pill toggle for list filters.
///
/// Named `AppFilterChip` to avoid colliding with Flutter's Material
/// `FilterChip` (which has a different visual + selection model). Active
/// state inverts to navy bg / white text; inactive uses white bg with a
/// 1.5px navy border.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;

    final bg = active ? colors.navy : colors.white;
    final fg = active ? colors.white : colors.body;
    final borderColor = active ? colors.navy : colors.border;
    final displayLabel = count != null ? '$label ($count)' : label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radii.pill),
        onTap: onTap,
        child: Container(
          key: const ValueKey('app-filter-chip-frame'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radii.pill),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                displayLabel,
                style: typo.displayXs.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
