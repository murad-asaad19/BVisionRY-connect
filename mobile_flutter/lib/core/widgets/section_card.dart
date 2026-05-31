import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Standard section panel used by profile-style surfaces.
///
/// Visual: white background, 12-radius rounded corners, 1px border, and
/// an optional uppercase eyebrow title (11px / muted / Dosis 600 / 0.6
/// letter-spacing) rendered above the body. Body content is provided via
/// [child] so callers can compose richer layouts inside.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.title, this.padding});

  /// Optional uppercase eyebrow rendered above the body. Omit for a
  /// headerless panel (e.g. a meta strip card with no semantic label).
  final String? title;

  /// Body content.
  final Widget child;

  /// Optional padding override. Defaults to 14px on all sides.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return Container(
      key: const ValueKey('section-card-frame'),
      decoration: BoxDecoration(
        color: c.white,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: c.border),
        boxShadow: Theme.of(context).extension<AppShadows>()!.card,
      ),
      padding: padding ?? EdgeInsets.all(spacing.cardLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: typo.displayXs.copyWith(
                color: c.muted,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: spacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}
