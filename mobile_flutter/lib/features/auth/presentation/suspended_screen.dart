import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/auth_service_provider.dart';
import '../providers/session_provider.dart';

/// Static destination for users whose `profiles.suspended_at` is set.
///
/// Per gallery section I5 the screen renders a danger-tinted exclamation
/// glyph, a strong "Account suspended" heading, an explanation paragraph, a
/// muted "What happens next" details panel (48-hour SLA + the email we'll
/// reach out on), the primary "Submit appeal" button, and a secondary "Sign
/// out". The route guard delivers the user here and removes them once the
/// suspension is lifted.
class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  Future<void> _openAppealMail(BuildContext context, WidgetRef ref) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: 'support@bvisionry.com',
      query: 'subject=${Uri.encodeComponent('Account appeal')}',
    );
    final bool launched = await canLaunchUrl(uri) && await launchUrl(uri);
    if (launched || !context.mounted) return;
    // No mail client available — fall back to a toast carrying the support
    // address so the user can still reach us.
    ref.read(toastServiceProvider.notifier).showToast(
          title: context.t('suspended.noMailClient'),
          intent: AppIntent.warning,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final String? email = ref.watch(currentSessionProvider)?.user.email;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  key: const Key('suspended.dangerGlyph'),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.dangerBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.error_outline,
                    size: 36,
                    color: colors.danger,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.t('suspended.titleStrong'),
                  style: typo.displayMd.copyWith(color: colors.danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('suspended.body'),
                  style: typo.bodyMd.copyWith(color: colors.body),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  key: const Key('suspended.whatHappensNext'),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.t('suspended.whatHappensNext'),
                        style: typo.displaySm.copyWith(color: colors.navy),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('suspended.sla'),
                        style: typo.bodySm.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (email == null || email.isEmpty)
                            ? context.t('suspended.emailNoticeNoEmail')
                            : context.t(
                                'suspended.emailNotice',
                                vars: <String, Object>{'email': email},
                              ),
                        style: typo.bodySm.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.section),
                AppButton(
                  key: const Key('appeal'),
                  label: context.t('suspended.submitAppeal'),
                  onPressed: () => _openAppealMail(context, ref),
                ),
                const SizedBox(height: 10),
                // Mockup I5: small footer note under the appeal CTA spelling
                // out the hard-tier consequence of repeat offenses.
                Text(
                  context.t('suspended.repeatOffenses'),
                  style: typo.bodySm.copyWith(color: colors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                AppButton(
                  key: const Key('sign-out'),
                  label: context.t('suspended.signOut'),
                  variant: AppButtonVariant.outlineDanger,
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
