import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Semantic intent shared across UI primitives (banner, pill, etc.).
enum Intent { neutral, info, success, warning, danger }

/// Resolved background / text / border colors for an [Intent].
@immutable
class IntentColors {
  const IntentColors({
    required this.bg,
    required this.text,
    required this.border,
  });

  final Color bg;
  final Color text;
  final Color border;
}

/// Resolves an [Intent] to concrete colors via the active [AppColors] theme
/// extension. Centralizing this means every intent-aware primitive renders
/// identically without duplicating colour maps.
IntentColors intentColors(BuildContext context, Intent intent) {
  final c = Theme.of(context).extension<AppColors>()!;
  return switch (intent) {
    Intent.neutral =>
      IntentColors(bg: c.surface, text: c.body, border: c.border),
    Intent.info =>
      IntentColors(bg: c.infoBg, text: c.info, border: c.infoBorder),
    Intent.success =>
      IntentColors(bg: c.successBg, text: c.success, border: c.successBorder),
    Intent.warning =>
      IntentColors(bg: c.warningBg, text: c.warning, border: c.warningBorder),
    Intent.danger =>
      IntentColors(bg: c.dangerBg, text: c.danger, border: c.dangerBorder),
  };
}
