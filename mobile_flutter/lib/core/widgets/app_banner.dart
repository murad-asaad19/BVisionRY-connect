import 'package:flutter/material.dart';

import '../i18n/i18n.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import 'app_icon_button.dart';
import 'variants.dart';

/// Inline banner / alert primitive.
///
/// Visual: 10-radius rounded rectangle, thin same-colour border, padding
/// matching the gallery (12 horizontal / 10 vertical), with an optional
/// title rendered above the body. When [onClose] is provided, an X icon is
/// shown in the top-right corner — keeping the dismiss target ≥ 14px while
/// preserving an extended hit slop via [InkResponse].
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.intent,
    required this.child,
    this.title,
    this.leadingIcon,
    this.onClose,
  });

  /// Semantic intent — drives the bg / text / border palette.
  final AppIntent intent;

  /// Optional title shown above the body.
  final String? title;

  /// Body content. Strings are wrapped in a styled Text automatically; any
  /// other widget is rendered as-is so callers can compose richer layouts.
  final Widget child;

  /// Optional icon shown to the left of the body, vertically aligned with
  /// the title (or body, when there's no title).
  final Widget? leadingIcon;

  /// When provided, renders the dismiss X icon and calls this on tap.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = intentColors(context, intent);
    final radii = Theme.of(context).extension<AppRadii>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;

    return Container(
      key: const ValueKey('app-banner-frame'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(radii.button),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingIcon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: leadingIcon,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: typo.displaySm.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: 2),
                ],
                DefaultTextStyle(
                  style: typo.bodyMd.copyWith(color: colors.text),
                  child: child,
                ),
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            AppIconButton(
              icon: Icons.close,
              label: context.t('common.close'),
              size: AppIconButtonSize.sm,
              onPressed: onClose,
            ),
          ],
        ],
      ),
    );
  }
}
