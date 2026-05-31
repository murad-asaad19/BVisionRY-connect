import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Uppercase eyebrow above a group of settings rows. Matches the gallery's
/// `.gh`: 11px navy uppercase, letter-spacing 0.5, 16px horizontal padding.
class SettingsGroupEyebrow extends StatelessWidget {
  const SettingsGroupEyebrow({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: typo.displayXs.copyWith(
          color: colors.navy,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Rounded white card that wraps a group of settings rows. 10px radius mirrors
/// the gallery's per-group container (`background:white; border-radius:10px;`).
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
