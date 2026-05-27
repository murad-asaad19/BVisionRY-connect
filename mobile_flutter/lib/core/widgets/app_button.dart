import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

/// Visual variants supported by [AppButton].
///
/// `disabled` is internal — the widget collapses to the disabled visual
/// whenever `disabled: true`, `loading: true`, or `onPressed: null` is set.
enum AppButtonVariant {
  primary,
  gold,
  outline,
  outlineDanger,
  danger,
  apple,
  disabled,
}

/// Size token for [AppButton]. `defaultSize` is the standard 13px label,
/// `small` shrinks padding and label to 11px (used inline in row actions).
enum AppButtonSize { defaultSize, small }

/// Branded primary action button.
///
/// Renders a 10-radius pill-with-corners button with a 1.5px stroke. The
/// `variant` chooses the fill / text / border palette; loading and disabled
/// states are visual collapses that also block the tap handler.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.defaultSize,
    this.fullWidth = true,
    this.loading = false,
    this.disabled = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;
  final bool loading;
  final bool disabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    // A null onPressed always reads as disabled — matches Flutter idiom
    // (ElevatedButton, etc.) and removes the disabled/onPressed double-set
    // boilerplate that was easy to forget at the call site.
    final visualDisabled = disabled || loading || onPressed == null;
    final v = visualDisabled ? AppButtonVariant.disabled : variant;

    final (bg, fg, borderColor) = switch (v) {
      AppButtonVariant.primary => (colors.navy, colors.white, colors.navy),
      AppButtonVariant.gold => (colors.gold, colors.navy, colors.gold),
      AppButtonVariant.outline => (colors.white, colors.navy, colors.navy),
      AppButtonVariant.outlineDanger => (
          colors.white,
          colors.danger,
          colors.danger,
        ),
      AppButtonVariant.danger => (
          colors.dangerBg,
          colors.danger,
          colors.dangerBorder,
        ),
      AppButtonVariant.apple => (Colors.black, colors.white, Colors.black),
      AppButtonVariant.disabled => (
          colors.slate100,
          colors.white,
          colors.slate100,
        ),
    };

    final padding = size == AppButtonSize.small
        ? const EdgeInsets.symmetric(horizontal: 11, vertical: 7)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);

    final child = Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: typo.displaySm.copyWith(
              color: fg,
              fontSize: size == AppButtonSize.small ? 11 : 13,
            ),
          ),
        ],
      ),
    );

    final button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(radii.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(radii.button),
        onTap: visualDisabled ? null : onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radii.button),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: child,
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
