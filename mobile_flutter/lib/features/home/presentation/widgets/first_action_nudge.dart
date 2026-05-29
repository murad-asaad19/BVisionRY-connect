import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_banner.dart';
import '../../../../core/widgets/variants.dart';
import '../../../intros/providers/intros_providers.dart';

/// First-run nudge below the daily picks (gallery B5, lines 1387-1389):
/// "First step: Send your first intro to one of today's matches." With the
/// muted "(Verify email first)" qualifier appended while the user's email is
/// still unverified.
///
/// Gated to users who have not yet sent any intro (derived from
/// [sentIntrosProvider]) — once they send their first intro the nudge
/// disappears. Self-collapses while the sent-intros list is loading or on
/// error so it never blocks the feed.
class FirstActionNudge extends ConsumerWidget {
  const FirstActionNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSent = ref.watch(sentIntrosProvider).maybeWhen(
          data: (list) => list.isNotEmpty,
          // While loading / on error, assume "has sent" so we don't flash the
          // first-run nudge at an established user mid-fetch.
          orElse: () => true,
        );
    if (hasSent) return const SizedBox.shrink();

    final User? user = ref.watch(supabaseClientProvider).auth.currentUser;
    final bool unverified = user != null && user.emailConfirmedAt == null;

    final c = Theme.of(context).extension<AppColors>()!;
    final t = Theme.of(context).extension<AppTypography>()!;
    final spacing = Theme.of(context).extension<AppSpacing>()!;

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
      child: AppBanner(
        key: const ValueKey<String>('home.firstActionNudge'),
        intent: AppIntent.info,
        title: context.t('home.firstAction.title'),
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: context.t('home.firstAction.body')),
              if (unverified)
                TextSpan(
                  text: ' ${context.t('home.firstAction.verifyFirst')}',
                  style: t.bodyMd.copyWith(color: c.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
