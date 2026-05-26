import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Warning-toned banner used wherever a planned server-side capability has
/// not yet shipped (spec §17.2 — `public_investor_page` toggle is the
/// canonical use site).
///
/// Visual: amber background + border, clock icon, two-line title / body.
/// Keep the body text short — the surrounding context already explains
/// what the user was trying to do.
class ComingSoonCard extends StatelessWidget {
  const ComingSoonCard({super.key, required this.title, required this.body});

  /// Localized title (e.g. "Public investor page").
  final String title;

  /// Localized body — typically `settings.publicInvestorPage.comingSoon`
  /// or any other "ships next release" message.
  final String body;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppRadii radii = Theme.of(context).extension<AppRadii>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warningBg,
        border: Border.all(color: colors.warningBorder),
        borderRadius: BorderRadius.circular(radii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(LucideIcons.clock, color: colors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: typo.displaySm.copyWith(color: colors.warning),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: typo.bodyMd.copyWith(color: colors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
