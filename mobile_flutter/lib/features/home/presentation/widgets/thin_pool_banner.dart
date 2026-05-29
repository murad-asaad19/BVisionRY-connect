import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gap.dart';
import '../../../../core/widgets/variants.dart';

/// Inline warning surfaced above the daily-matches list when the server
/// returned fewer than 3 picks. Tapping the CTA pushes the user back into
/// the onboarding-goal step so they can refine their goal description and
/// (hopefully) unlock more matches tomorrow.
class ThinPoolBanner extends StatelessWidget {
  const ThinPoolBanner({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.sm,
      ),
      child: AppBanner(
        // Niche-pool treatment per spec §4 — a calm, confident "we're being
        // picky" note, not an alarming warning. Mockup C2 uses the neutral
        // (muted) banner style.
        intent: AppIntent.neutral,
        title: context.t('discovery.thinPoolTitle'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.t(
                'discovery.thinPoolBannerFixed',
                vars: <String, Object>{'count': count},
              ),
            ),
            Gap(spacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                key: const Key('home.thinPool.refineGoal'),
                label: context.t('discovery.thinPoolAction'),
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                fullWidth: false,
                icon: Icons.tune,
                onPressed: () {
                  Haptics.light();
                  context.push(Routes.onboardingGoal);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
