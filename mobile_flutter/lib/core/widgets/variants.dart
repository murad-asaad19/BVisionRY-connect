import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Semantic intent shared across UI primitives (banner, pill, etc.).
///
/// Renamed from `Intent` to avoid a clash with Flutter's own
/// `package:flutter/src/widgets/actions.dart` `Intent` class — both live in
/// callers' import scopes side by side.
enum AppIntent { neutral, info, success, warning, danger }

/// Resolved background / text / border colors for an [AppIntent].
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

/// Resolves an [AppIntent] to concrete colors via the active [AppColors]
/// theme extension. Centralizing this means every intent-aware primitive
/// renders identically without duplicating colour maps.
IntentColors intentColors(BuildContext context, AppIntent intent) {
  final c = Theme.of(context).extension<AppColors>()!;
  return switch (intent) {
    AppIntent.neutral =>
      IntentColors(bg: c.surface, text: c.body, border: c.border),
    AppIntent.info =>
      IntentColors(bg: c.infoBg, text: c.info, border: c.infoBorder),
    AppIntent.success =>
      IntentColors(bg: c.successBg, text: c.success, border: c.successBorder),
    AppIntent.warning =>
      IntentColors(bg: c.warningBg, text: c.warning, border: c.warningBorder),
    AppIntent.danger =>
      IntentColors(bg: c.dangerBg, text: c.danger, border: c.dangerBorder),
  };
}
