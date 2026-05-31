import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Size token for [AppIconButton]. The visual chip is `sm`=32, `md`=40,
/// `lg`=44 — sizes under 44 are wrapped in a 44dp `SizedBox` so the touch
/// target meets the WCAG 2.5.5 / Apple HIG minimum.
enum AppIconButtonSize { sm, md, lg }

/// Visual variant for [AppIconButton].
///
/// `plain` is transparent (toolbar icons); `subtle` paints a goldPale
/// circle behind the glyph for emphasis (FAB-style row actions); `navy`
/// inverts to a filled navy disc with a white icon; `danger` is a
/// transparent chip with a danger-tinted glyph (destructive row actions).
enum AppIconButtonVariant { plain, subtle, navy, danger }

/// Compact icon-only button. Always renders a ≥44dp tap target; the chip
/// itself can shrink while hitTest area stays accessible.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.size = AppIconButtonSize.md,
    this.variant = AppIconButtonVariant.plain,
    this.disabled = false,
  });

  final IconData icon;

  /// Required for accessibility — screen-readers announce this string.
  final String label;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final AppIconButtonVariant variant;
  final bool disabled;

  static const _dim = <AppIconButtonSize, double>{
    AppIconButtonSize.sm: 32,
    AppIconButtonSize.md: 40,
    AppIconButtonSize.lg: 44,
  };
  static const _iconSize = <AppIconButtonSize, double>{
    AppIconButtonSize.sm: 16,
    AppIconButtonSize.md: 20,
    AppIconButtonSize.lg: 22,
  };
  static const _minTarget = 44.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final chipDim = _dim[size]!;
    final iconDim = _iconSize[size]!;
    final hitDim = chipDim < _minTarget ? _minTarget : chipDim;

    final Color bg;
    final Color iconColor;
    switch (variant) {
      case AppIconButtonVariant.plain:
        bg = Colors.transparent;
        iconColor = disabled ? colors.muted : colors.navy;
      case AppIconButtonVariant.subtle:
        bg = colors.goldPale;
        iconColor = disabled ? colors.muted : colors.navy;
      case AppIconButtonVariant.navy:
        bg = colors.navy;
        iconColor = disabled ? colors.muted : colors.white;
      case AppIconButtonVariant.danger:
        bg = Colors.transparent;
        iconColor = disabled ? colors.muted : colors.danger;
    }

    final chip = Container(
      key: const ValueKey('app-icon-button-frame'),
      width: chipDim,
      height: chipDim,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: iconDim, color: iconColor),
    );

    return Semantics(
      button: true,
      label: label,
      enabled: !disabled && onPressed != null,
      child: SizedBox(
        key: const ValueKey('app-icon-button-hit'),
        width: hitDim,
        height: hitDim,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkResponse(
            radius: hitDim / 2,
            onTap: disabled ? null : onPressed,
            child: Center(child: chip),
          ),
        ),
      ),
    );
  }
}
