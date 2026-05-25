import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/app_banner.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppBanner(
        intent: AppIntent.warning,
        title: context.t('discovery.thinPoolTitle'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              context.t(
                'discovery.thinPoolBanner',
                vars: <String, Object>{'count': count},
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => context.push(Routes.onboardingGoal),
              child: Text(
                context.t('discovery.thinPoolAction'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
