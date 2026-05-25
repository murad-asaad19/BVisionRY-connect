import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Single tappable row used inside Settings / Profile menus.
///
/// Layout: optional [icon] (left), [label] + optional [description] in a
/// stacked column, optional [trailing] widget, and a chevron-right glyph
/// when [onTap] is provided. The whole row is wrapped in an [InkWell]
/// so taps ripple over the row's bounds.
///
/// When [destructive] is true the label + icon are coloured danger to
/// signal a destructive action (e.g. "Sign out", "Delete account").
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.icon,
    this.description,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final labelColor = destructive ? c.danger : c.body;
    final iconColor = destructive ? c.danger : c.navy;

    return Material(
      color: c.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          key: const ValueKey('settings-row-frame'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: typo.displaySm.copyWith(color: labelColor),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: typo.bodySm.copyWith(color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (onTap != null && trailing == null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: c.muted, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
