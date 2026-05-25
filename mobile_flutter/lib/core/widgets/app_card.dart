import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Visual variants for [AppCard].
///
/// `defaultVariant` is the standard white-fill card with a 1px border;
/// `featured` adds the gold 1.5px border and the `goldPale → white` linear
/// gradient used to highlight premium / promoted rows.
enum AppCardVariant { defaultVariant, featured }

/// Container primitive matching the gallery's `.card` / `.card-featured`
/// CSS. Wraps its child in 14-radius rounded rectangle with 12px padding.
///
/// When [onTap] is provided, the entire card becomes a Material ink
/// surface that ripples on press. The gradient + border are preserved in
/// the tappable path because the InkWell is rendered on top of the
/// decoration via `Material.transparent`.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.defaultVariant,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;

    final isFeatured = variant == AppCardVariant.featured;
    final borderRadius = BorderRadius.circular(radii.card);
    final decoration = BoxDecoration(
      color: isFeatured ? null : colors.white,
      gradient: isFeatured
          ? LinearGradient(
              colors: [colors.goldPale, colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: borderRadius,
      border: Border.all(
        color: isFeatured ? colors.gold : colors.border,
        width: isFeatured ? 1.5 : 1,
      ),
    );

    final body = Padding(
      padding: padding ?? EdgeInsets.all(spacing.card),
      child: child,
    );

    return Container(
      key: const ValueKey('app-card-frame'),
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: onTap,
                child: body,
              ),
            )
          : body,
    );
  }
}
