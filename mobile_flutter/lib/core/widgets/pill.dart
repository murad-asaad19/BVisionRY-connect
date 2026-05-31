import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import 'variants.dart';

/// Visual variants for [Pill].
///
/// Brand variants (`defaultVariant`, `solid`, `navy`, `outline`, `muted`) are
/// hand-tuned to the gallery; semantic variants delegate to
/// [intentColors] so every intent-aware primitive renders identically.
enum PillVariant {
  defaultVariant,
  solid,
  navy,
  outline,
  muted,
  tag,
  info,
  success,
  warning,
  danger,
}

/// Size token for [Pill]. `sm` is 20px tall (3×9 padding); `md` is 26px
/// tall (4×11 padding) — both render the rounded-pill chrome unchanged.
enum PillSize { sm, md }

/// Rounded-pill chip primitive (matches the gallery's `.pill` CSS).
///
/// Used for inline meta (status badges, tag rows, opportunity kind chips,
/// office-hours availability). Reuse [intentColors] for semantic variants
/// so colour mapping stays centralized.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.variant = PillVariant.defaultVariant,
    this.size = PillSize.sm,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final PillVariant variant;
  final PillSize size;
  final IconData? icon;

  /// Optional explicit-color overrides. When [backgroundColor] is non-null
  /// the resolved [variant] palette is ignored and these colours are used
  /// instead — lets callers render an arbitrary palette (e.g. the violet
  /// "advising" kind) without minting a dedicated variant.
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  static const _intentMap = <PillVariant, AppIntent>{
    PillVariant.info: AppIntent.info,
    PillVariant.success: AppIntent.success,
    PillVariant.warning: AppIntent.warning,
    PillVariant.danger: AppIntent.danger,
    PillVariant.muted: AppIntent.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;

    final intent = _intentMap[variant];
    Color bg;
    Color fg;
    Color? border;
    if (intent != null) {
      final c = intentColors(context, intent);
      bg = c.bg;
      fg = c.text;
      border = null;
    } else {
      switch (variant) {
        case PillVariant.solid:
          bg = palette.gold;
          fg = palette.navyDark;
          border = null;
        case PillVariant.navy:
          bg = palette.navyFill;
          fg = palette.onNavy;
          border = null;
        case PillVariant.outline:
          bg = palette.white;
          fg = palette.navy;
          border = palette.navy;
        case PillVariant.tag:
          bg = palette.slate100;
          fg = palette.muted;
          border = null;
        case PillVariant.defaultVariant:
        case PillVariant.info:
        case PillVariant.success:
        case PillVariant.warning:
        case PillVariant.danger:
        case PillVariant.muted:
          bg = palette.goldPale;
          fg = palette.navyDark;
          border = null;
      }
    }

    // Explicit overrides win over the resolved variant palette.
    if (backgroundColor != null) {
      bg = backgroundColor!;
      fg = foregroundColor ?? fg;
      border = borderColor;
    }

    final padding = size == PillSize.sm
        ? const EdgeInsets.symmetric(horizontal: 9, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 11, vertical: 4);
    final fontSize = size == PillSize.sm ? 10.0 : 11.0;

    return Container(
      key: const ValueKey('pill-frame'),
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radii.pill),
        border: border != null ? Border.all(color: border, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: typo.displayXs.copyWith(
              color: fg,
              fontSize: fontSize,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
